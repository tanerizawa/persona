import bcrypt from 'bcryptjs';
import jwt, { SignOptions } from 'jsonwebtoken';
import crypto from 'crypto';
import { prisma } from '../config/database';
import { ApiError, JwtPayload, LoginRequest, RegisterRequest } from '../types';

export class ProductionAuthService {
  private static readonly SALT_ROUNDS = parseInt(process.env.BCRYPT_ROUNDS || '12');
  private static readonly JWT_SECRET = process.env.JWT_SECRET!;
  private static readonly JWT_ACCESS_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '15m';
  private static readonly JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '7d';
  private static readonly MAX_FAILED_ATTEMPTS = 5;
  private static readonly LOCK_TIME = 15 * 60 * 1000; // 15 minutes

  static async register(data: RegisterRequest & { deviceId: string; deviceInfo?: any }): Promise<{
    user: any;
    accessToken: string;
    refreshToken: string;
    requiresVerification: boolean;
  }> {
    const { email, password, name, deviceId, deviceInfo } = data;

    try {
      // Check if user already exists
      const existingUser = await prisma.user.findUnique({
        where: { email: email.toLowerCase() }
      });

      if (existingUser) {
        throw new ApiError(409, 'Email already registered');
      }

      // Validate password strength
      this.validatePassword(password);

      // Hash password
      const passwordHash = await bcrypt.hash(password, this.SALT_ROUNDS);
      
      // Generate verification token
      const verificationToken = crypto.randomBytes(32).toString('hex');

      // Create user
      const user = await prisma.user.create({
        data: {
          email: email.toLowerCase(),
          passwordHash,
          displayName: name,
          verificationToken,
          accountStatus: 'pending'
        }
      });

      // Generate tokens
      const accessToken = this.generateAccessToken(user.id, user.email);
      const refreshToken = this.generateRefreshToken(user.id, user.email);

      // Create session
      await this.createSession(user.id, deviceId, accessToken, refreshToken, deviceInfo);

      // Log security event
      await this.logSecurityEvent(user.id, 'user_registered', 'low', 'New user registration', deviceInfo?.ipAddress);

      return {
        user: this.sanitizeUser(user),
        accessToken,
        refreshToken,
        requiresVerification: true
      };
    } catch (error) {
      // Re-throw ApiError as is, convert other errors
      if (error instanceof ApiError) {
        throw error;
      }
      console.error('Registration unexpected error:', error);
      throw new ApiError(500, 'Gagal membuat akun pengguna');
    }
  }

  static async login(data: LoginRequest & { deviceId: string; deviceInfo?: any }): Promise<{
    user: any;
    accessToken: string;
    refreshToken: string;
  }> {
    const { email, password, deviceId, deviceInfo } = data;

    try {
      // Find user
      const user = await prisma.user.findUnique({
        where: { email: email.toLowerCase() }
      });

      if (!user) {
        await this.logSecurityEvent(null, 'login_failed', 'medium', 'Login attempt with non-existent email', deviceInfo?.ipAddress);
        throw new ApiError(401, 'Email atau password salah');
      }

      // Check if account is locked
      if (user.lockedUntil && user.lockedUntil > new Date()) {
        await this.logSecurityEvent(user.id, 'login_blocked', 'high', 'Login attempt on locked account', deviceInfo?.ipAddress);
        throw new ApiError(423, 'Akun terkunci. Coba lagi nanti.');
      }

      // Verify password
      const isValidPassword = await bcrypt.compare(password, user.passwordHash);
      
      if (!isValidPassword) {
        // Increment failed attempts
        await this.handleFailedLogin(user.id, deviceInfo?.ipAddress);
        throw new ApiError(401, 'Email atau password salah');
      }

      // Check account status
      if (user.accountStatus === 'suspended') {
        await this.logSecurityEvent(user.id, 'login_suspended', 'high', 'Login attempt on suspended account', deviceInfo?.ipAddress);
        throw new ApiError(403, 'Akun Anda telah dinonaktifkan');
      }

      // Reset failed attempts on successful login
      if (user.failedLoginAttempts > 0) {
        await prisma.user.update({
          where: { id: user.id },
          data: {
            failedLoginAttempts: 0,
            lockedUntil: null,
            lastLogin: new Date()
          }
        });
      } else {
        await prisma.user.update({
          where: { id: user.id },
          data: { lastLogin: new Date() }
        });
      }

      // Generate tokens
      const accessToken = this.generateAccessToken(user.id, user.email);
      const refreshToken = this.generateRefreshToken(user.id, user.email);

      // Create/update session
      await this.createSession(user.id, deviceId, accessToken, refreshToken, deviceInfo);

      // Log successful login
      await this.logSecurityEvent(user.id, 'login_success', 'low', 'Successful login', deviceInfo?.ipAddress);

      return {
        user: this.sanitizeUser(user),
        accessToken,
        refreshToken
      };
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError(500, 'Terjadi kesalahan saat login');
    }
  }

  static async refreshToken(refreshToken: string): Promise<{
    accessToken: string;
    refreshToken: string;
  }> {
    try {
      // Verify refresh token
      const decoded = jwt.verify(refreshToken, this.JWT_SECRET) as JwtPayload;
      
      // Find session
      const session = await prisma.userSession.findFirst({
        where: {
          userId: decoded.userId,
          refreshTokenHash: this.hashToken(refreshToken),
          isActive: true,
          expiresAt: { gte: new Date() }
        },
        include: { user: true }
      });

      if (!session) {
        throw new ApiError(401, 'Refresh token tidak valid');
      }

      // Check user status
      if (session.user.accountStatus !== 'active') {
        throw new ApiError(403, 'Akun tidak aktif');
      }

      // Generate new tokens
      const newAccessToken = this.generateAccessToken(session.userId, session.user.email);
      const newRefreshToken = this.generateRefreshToken(session.userId, session.user.email);

      // Update session
      await prisma.userSession.update({
        where: { id: session.id },
        data: {
          accessTokenHash: this.hashToken(newAccessToken),
          refreshTokenHash: this.hashToken(newRefreshToken),
          lastActive: new Date()
        }
      });

      return {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken
      };
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError(401, 'Token tidak valid');
    }
  }

  static async logout(userId: string, deviceId: string): Promise<void> {
    try {
      await prisma.userSession.updateMany({
        where: {
          userId,
          deviceId,
          isActive: true
        },
        data: { isActive: false }
      });

      await this.logSecurityEvent(userId, 'logout', 'low', 'User logout');
    } catch (error) {
      throw new ApiError(500, 'Gagal logout');
    }
  }

  static async verifyEmail(token: string): Promise<void> {
    try {
      const user = await prisma.user.findFirst({
        where: { verificationToken: token }
      });

      if (!user) {
        throw new ApiError(400, 'Token verifikasi tidak valid');
      }

      await prisma.user.update({
        where: { id: user.id },
        data: {
          emailVerified: true,
          verificationToken: null,
          accountStatus: 'active'
        }
      });

      await this.logSecurityEvent(user.id, 'email_verified', 'low', 'Email verification completed');
    } catch (error) {
      if (error instanceof ApiError) throw error;
      throw new ApiError(500, 'Gagal verifikasi email');
    }
  }

  // Biometric Authentication Methods
  static async setupBiometric(
    userId: string, 
    deviceId: string, 
    biometricHash: string, 
    biometricType?: string
  ): Promise<void> {
    try {
      // Create or update biometric credential
      await prisma.biometricCredential.upsert({
        where: {
          userId_deviceId: {
            userId,
            deviceId
          }
        },
        update: {
          biometricHash,
          biometricType: biometricType || 'fingerprint',
          isActive: true,
          updatedAt: new Date()
        },
        create: {
          userId,
          deviceId,
          biometricHash,
          biometricType: biometricType || 'fingerprint',
          isActive: true
        }
      });

      await this.logSecurityEvent(userId, 'biometric_setup', 'low', 'Biometric authentication setup');
    } catch (error) {
      throw new ApiError(500, 'Failed to setup biometric authentication');
    }
  }

  static async verifyBiometric(
    userId: string, 
    deviceId: string, 
    biometricHash: string
  ): Promise<boolean> {
    try {
      const credential = await prisma.biometricCredential.findUnique({
        where: {
          userId_deviceId: {
            userId,
            deviceId
          }
        }
      });

      if (!credential || !credential.isActive) {
        await this.logSecurityEvent(userId, 'biometric_failed', 'medium', 'Biometric verification failed - no credential');
        return false;
      }

      const isValid = credential.biometricHash === biometricHash;

      if (isValid) {
        // Update last used timestamp
        await prisma.biometricCredential.update({
          where: { id: credential.id },
          data: { lastUsed: new Date() }
        });

        await this.logSecurityEvent(userId, 'biometric_success', 'low', 'Biometric verification successful');
      } else {
        await this.logSecurityEvent(userId, 'biometric_failed', 'medium', 'Biometric verification failed - invalid hash');
      }

      return isValid;
    } catch (error) {
      await this.logSecurityEvent(userId, 'biometric_error', 'high', 'Biometric verification error');
      return false;
    }
  }

  static async disableBiometric(userId: string, deviceId: string): Promise<void> {
    try {
      await prisma.biometricCredential.updateMany({
        where: {
          userId,
          deviceId
        },
        data: {
          isActive: false,
          updatedAt: new Date()
        }
      });

      await this.logSecurityEvent(userId, 'biometric_disabled', 'low', 'Biometric authentication disabled');
    } catch (error) {
      throw new ApiError(500, 'Failed to disable biometric authentication');
    }
  }

  static async getBiometricStatus(userId: string, deviceId: string): Promise<{
    isEnabled: boolean;
    biometricType?: string;
    lastUsed?: Date;
  }> {
    try {
      const credential = await prisma.biometricCredential.findUnique({
        where: {
          userId_deviceId: {
            userId,
            deviceId
          }
        }
      });

      return {
        isEnabled: credential?.isActive || false,
        biometricType: credential?.biometricType,
        lastUsed: credential?.lastUsed || undefined
      };
    } catch (error) {
      return { isEnabled: false };
    }
  }

  // Helper methods
  private static generateAccessToken(userId: string, email?: string): string {
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      throw new Error('JWT_SECRET environment variable is not set');
    }
    const options: SignOptions = { expiresIn: this.JWT_ACCESS_EXPIRES_IN as any };
    return jwt.sign({ id: userId, email, type: 'access' }, jwtSecret, options);
  }

  private static generateRefreshToken(userId: string, email?: string): string {
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      throw new Error('JWT_SECRET environment variable is not set');
    }
    const options: SignOptions = { expiresIn: this.JWT_REFRESH_EXPIRES_IN as any };
    return jwt.sign({ id: userId, email, type: 'refresh' }, jwtSecret, options);
  }

  private static hashToken(token: string): string {
    return crypto.createHash('sha256').update(token).digest('hex');
  }

  private static async createSession(
    userId: string,
    deviceId: string,
    accessToken: string,
    refreshToken: string,
    deviceInfo?: any
  ): Promise<void> {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    // Use upsert to handle existing sessions
    await prisma.userSession.upsert({
      where: {
        userId_deviceId: {
          userId,
          deviceId
        }
      },
      update: {
        accessTokenHash: this.hashToken(accessToken),
        refreshTokenHash: this.hashToken(refreshToken),
        expiresAt,
        ipAddress: deviceInfo?.ipAddress,
        userAgent: deviceInfo?.userAgent,
        isActive: true,
        lastActive: new Date()
      },
      create: {
        userId,
        deviceId,
        deviceName: deviceInfo?.deviceName,
        deviceType: deviceInfo?.deviceType,
        accessTokenHash: this.hashToken(accessToken),
        refreshTokenHash: this.hashToken(refreshToken),
        expiresAt,
        ipAddress: deviceInfo?.ipAddress,
        userAgent: deviceInfo?.userAgent
      }
    });
  }

  private static async handleFailedLogin(userId: string, ipAddress?: string): Promise<void> {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) return;

    const failedAttempts = user.failedLoginAttempts + 1;
    const updates: any = { failedLoginAttempts: failedAttempts };

    if (failedAttempts >= this.MAX_FAILED_ATTEMPTS) {
      updates.lockedUntil = new Date(Date.now() + this.LOCK_TIME);
      await this.logSecurityEvent(userId, 'account_locked', 'high', `Account locked after ${failedAttempts} failed attempts`, ipAddress);
    } else {
      await this.logSecurityEvent(userId, 'login_failed', 'medium', `Failed login attempt ${failedAttempts}`, ipAddress);
    }

    await prisma.user.update({
      where: { id: userId },
      data: updates
    });
  }

  private static async logSecurityEvent(
    userId: string | null,
    eventType: string,
    severity: string,
    description: string,
    ipAddress?: string,
    userAgent?: string
  ): Promise<void> {
    try {
      await prisma.securityEvent.create({
        data: {
          userId,
          eventType,
          severity,
          description,
          ipAddress,
          userAgent
        }
      });
    } catch (error) {
      console.error('Failed to log security event:', error);
    }
  }

  static async getUserProfile(userId: string): Promise<any> {
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) {
      throw new ApiError(404, 'User not found');
    }

    return this.sanitizeUser(user);
  }

  static async updateUserProfile(userId: string, data: {
    name?: string;
    bio?: string;
    preferences?: any;
  }): Promise<any> {
    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(data.name && { name: data.name }),
        ...(data.bio && { bio: data.bio }),
        ...(data.preferences && { preferences: data.preferences }),
        updatedAt: new Date()
      }
    });

    return this.sanitizeUser(user);
  }

  private static validatePassword(password: string): void {
    if (password.length < 8) {
      throw new ApiError(400, 'Password minimal 8 karakter');
    }
    if (!/(?=.*[a-z])/.test(password)) {
      throw new ApiError(400, 'Password harus mengandung huruf kecil');
    }
    if (!/(?=.*[A-Z])/.test(password)) {
      throw new ApiError(400, 'Password harus mengandung huruf besar');
    }
    if (!/(?=.*\d)/.test(password)) {
      throw new ApiError(400, 'Password harus mengandung angka');
    }
  }

  private static sanitizeUser(user: any): any {
    const { passwordHash, verificationToken, ...sanitized } = user;
    
    // Map displayName to name for API consistency
    if (user.displayName) {
      sanitized.name = user.displayName;
    }
    
    return sanitized;
  }
}
