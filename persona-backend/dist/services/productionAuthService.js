"use strict";
var __rest = (this && this.__rest) || function (s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
        t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
        for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
            if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
                t[p[i]] = s[p[i]];
        }
    return t;
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProductionAuthService = void 0;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const crypto_1 = __importDefault(require("crypto"));
const database_1 = require("../config/database");
const types_1 = require("../types");
class ProductionAuthService {
    static async register(data) {
        const { email, password, name, deviceId, deviceInfo } = data;
        try {
            // Check if user already exists
            const existingUser = await database_1.prisma.user.findUnique({
                where: { email: email.toLowerCase() }
            });
            if (existingUser) {
                throw new types_1.ApiError(409, 'Email already registered');
            }
            // Validate password strength
            this.validatePassword(password);
            // Hash password
            const passwordHash = await bcryptjs_1.default.hash(password, this.SALT_ROUNDS);
            // Generate verification token
            const verificationToken = crypto_1.default.randomBytes(32).toString('hex');
            // Auto-activate for development environment
            const isDevelopment = process.env.NODE_ENV === 'development';
            const accountStatus = isDevelopment ? 'active' : 'pending';
            // Create user
            const user = await database_1.prisma.user.create({
                data: {
                    email: email.toLowerCase(),
                    passwordHash,
                    displayName: name,
                    verificationToken,
                    accountStatus
                }
            });
            // Generate tokens
            const accessToken = this.generateAccessToken(user.id, user.email);
            const refreshToken = this.generateRefreshToken(user.id, user.email, deviceId);
            // Create session
            await this.createSession(user.id, deviceId, accessToken, refreshToken, deviceInfo);
            // Log security event
            await this.logSecurityEvent(user.id, 'user_registered', 'low', 'New user registration', deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.ipAddress);
            return {
                user: this.sanitizeUser(user),
                accessToken,
                refreshToken,
                requiresVerification: true
            };
        }
        catch (error) {
            // Re-throw ApiError as is, convert other errors
            if (error instanceof types_1.ApiError) {
                throw error;
            }
            console.error('Registration unexpected error:', error);
            throw new types_1.ApiError(500, 'Gagal membuat akun pengguna');
        }
    }
    static async login(data) {
        const { email, password, deviceId, deviceInfo } = data;
        try {
            // Find user
            const user = await database_1.prisma.user.findUnique({
                where: { email: email.toLowerCase() }
            });
            if (!user) {
                await this.logSecurityEvent(null, 'login_failed', 'medium', 'Login attempt with non-existent email', deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.ipAddress);
                throw new types_1.ApiError(401, 'Email atau password salah');
            }
            // Check if account is locked
            if (user.lockedUntil && user.lockedUntil > new Date()) {
                await this.logSecurityEvent(user.id, 'login_blocked', 'high', 'Login attempt on locked account', deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.ipAddress);
                throw new types_1.ApiError(423, 'Akun terkunci. Coba lagi nanti.');
            }
            // Verify password
            const isValidPassword = await bcryptjs_1.default.compare(password, user.passwordHash);
            if (!isValidPassword) {
                // Increment failed attempts
                await this.handleFailedLogin(user.id, deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.ipAddress);
                throw new types_1.ApiError(401, 'Email atau password salah');
            }
            // Check account status
            if (user.accountStatus === 'suspended') {
                await this.logSecurityEvent(user.id, 'login_suspended', 'high', 'Login attempt on suspended account', deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.ipAddress);
                throw new types_1.ApiError(403, 'Akun Anda telah dinonaktifkan');
            }
            // Auto-activate pending accounts for development/testing
            if (user.accountStatus === 'pending') {
                console.log('🔓 Auto-activating pending account for development:', user.id);
                await database_1.prisma.user.update({
                    where: { id: user.id },
                    data: { accountStatus: 'active' }
                });
                await this.logSecurityEvent(user.id, 'account_activated', 'low', 'Account auto-activated on login');
            }
            // Reset failed attempts on successful login
            if (user.failedLoginAttempts > 0) {
                await database_1.prisma.user.update({
                    where: { id: user.id },
                    data: {
                        failedLoginAttempts: 0,
                        lockedUntil: null,
                        lastLogin: new Date()
                    }
                });
            }
            else {
                await database_1.prisma.user.update({
                    where: { id: user.id },
                    data: { lastLogin: new Date() }
                });
            }
            // Generate tokens
            const accessToken = this.generateAccessToken(user.id, user.email);
            const refreshToken = this.generateRefreshToken(user.id, user.email, deviceId);
            // Create/update session
            await this.createSession(user.id, deviceId, accessToken, refreshToken, deviceInfo);
            // Log successful login
            await this.logSecurityEvent(user.id, 'login_success', 'low', 'Successful login', deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.ipAddress);
            return {
                user: this.sanitizeUser(user),
                accessToken,
                refreshToken
            };
        }
        catch (error) {
            if (error instanceof types_1.ApiError)
                throw error;
            throw new types_1.ApiError(500, 'Terjadi kesalahan saat login');
        }
    }
    static async refreshToken(refreshToken, deviceId) {
        try {
            // Verify refresh token
            const decoded = jsonwebtoken_1.default.verify(refreshToken, this.JWT_SECRET);
            console.log('🔄 [RefreshToken] JWT decoded:', {
                userId: decoded.id,
                email: decoded.email,
                jwtDeviceId: decoded.deviceId
            });
            const tokenHash = this.hashToken(refreshToken);
            console.log('🔑 [RefreshToken] Token hash:', tokenHash.substring(0, 16) + '...');
            // Validate deviceId if provided in request body or JWT
            const expectedDeviceId = deviceId || decoded.deviceId;
            if (expectedDeviceId) {
                console.log('🔒 [RefreshToken] Device ID validation:', {
                    requestDeviceId: deviceId,
                    jwtDeviceId: decoded.deviceId,
                    expectedDeviceId
                });
            }
            // Build session query with deviceId validation if available
            const sessionQuery = {
                userId: decoded.id, // JWT contains 'id' field, but DB stores as 'userId'
                refreshTokenHash: tokenHash,
                isActive: true,
                expiresAt: { gte: new Date() }
            };
            // Add deviceId to query if available for additional security
            if (expectedDeviceId) {
                sessionQuery.deviceId = expectedDeviceId;
            }
            // Find session using correct field name from JWT (id, not userId)
            const session = await database_1.prisma.userSession.findFirst({
                where: sessionQuery,
                include: { user: true }
            });
            if (!session) {
                console.log('🚨 [RefreshToken] Session not found. Debug info:');
                console.log('   - Looking for userId:', decoded.id);
                console.log('   - Token hash:', tokenHash.substring(0, 16) + '...');
                // Debug: Check all sessions for this user
                const allSessions = await database_1.prisma.userSession.findMany({
                    where: { userId: decoded.id },
                    select: {
                        id: true,
                        deviceId: true,
                        isActive: true,
                        expiresAt: true,
                        refreshTokenHash: true,
                        lastActive: true,
                        createdAt: true
                    }
                });
                console.log('🔍 [RefreshToken] All sessions for user:', allSessions.map(s => ({
                    id: s.id,
                    deviceId: s.deviceId,
                    isActive: s.isActive,
                    expired: s.expiresAt < new Date(),
                    tokenHashMatch: s.refreshTokenHash === tokenHash,
                    actualHash: s.refreshTokenHash.substring(0, 16) + '...',
                    expectedHash: tokenHash.substring(0, 16) + '...',
                    lastActive: s.lastActive,
                    createdAt: s.createdAt
                })));
                throw new types_1.ApiError(401, 'Refresh token tidak valid');
            }
            // Check user status - allow both active and pending for development
            if (session.user.accountStatus === 'suspended') {
                throw new types_1.ApiError(403, 'Akun telah dinonaktifkan');
            }
            if (session.user.accountStatus !== 'active' && session.user.accountStatus !== 'pending') {
                throw new types_1.ApiError(403, 'Akun tidak aktif');
            }
            // Generate new tokens
            const newAccessToken = this.generateAccessToken(session.userId, session.user.email);
            const newRefreshToken = this.generateRefreshToken(session.userId, session.user.email, session.deviceId);
            console.log('🔄 [RefreshToken] Updating session with new tokens');
            // Update session with transaction to prevent race condition
            await database_1.prisma.$transaction(async (tx) => {
                await tx.userSession.update({
                    where: { id: session.id },
                    data: {
                        accessTokenHash: this.hashToken(newAccessToken),
                        refreshTokenHash: this.hashToken(newRefreshToken),
                        lastActive: new Date()
                    }
                });
            });
            console.log('✅ [RefreshToken] Token refresh completed successfully');
            return {
                accessToken: newAccessToken,
                refreshToken: newRefreshToken
            };
        }
        catch (error) {
            if (error instanceof jsonwebtoken_1.default.JsonWebTokenError) {
                console.log('🚨 [RefreshToken] JWT Error:', error.message);
                throw new types_1.ApiError(401, 'Token tidak valid');
            }
            if (error instanceof types_1.ApiError) {
                console.log('🚨 [RefreshToken] Known error:', error.message);
                throw error;
            }
            console.error('🚨 [RefreshToken] Unexpected error:', error);
            throw new types_1.ApiError(500, 'Internal server error');
        }
    }
    static async logout(userId, deviceId) {
        try {
            await database_1.prisma.userSession.updateMany({
                where: {
                    userId,
                    deviceId,
                    isActive: true
                },
                data: { isActive: false }
            });
            await this.logSecurityEvent(userId, 'logout', 'low', 'User logout');
        }
        catch (error) {
            throw new types_1.ApiError(500, 'Gagal logout');
        }
    }
    static async verifyEmail(token) {
        try {
            const user = await database_1.prisma.user.findFirst({
                where: { verificationToken: token }
            });
            if (!user) {
                throw new types_1.ApiError(400, 'Token verifikasi tidak valid');
            }
            await database_1.prisma.user.update({
                where: { id: user.id },
                data: {
                    emailVerified: true,
                    verificationToken: null,
                    accountStatus: 'active'
                }
            });
            await this.logSecurityEvent(user.id, 'email_verified', 'low', 'Email verification completed');
        }
        catch (error) {
            if (error instanceof types_1.ApiError)
                throw error;
            throw new types_1.ApiError(500, 'Gagal verifikasi email');
        }
    }
    // Biometric Authentication Methods
    static async setupBiometric(userId, deviceId, biometricHash, biometricType) {
        try {
            // Create or update biometric credential
            await database_1.prisma.biometricCredential.upsert({
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
        }
        catch (error) {
            throw new types_1.ApiError(500, 'Failed to setup biometric authentication');
        }
    }
    static async verifyBiometric(userId, deviceId, biometricHash) {
        try {
            const credential = await database_1.prisma.biometricCredential.findUnique({
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
                await database_1.prisma.biometricCredential.update({
                    where: { id: credential.id },
                    data: { lastUsed: new Date() }
                });
                await this.logSecurityEvent(userId, 'biometric_success', 'low', 'Biometric verification successful');
            }
            else {
                await this.logSecurityEvent(userId, 'biometric_failed', 'medium', 'Biometric verification failed - invalid hash');
            }
            return isValid;
        }
        catch (error) {
            await this.logSecurityEvent(userId, 'biometric_error', 'high', 'Biometric verification error');
            return false;
        }
    }
    static async disableBiometric(userId, deviceId) {
        try {
            await database_1.prisma.biometricCredential.updateMany({
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
        }
        catch (error) {
            throw new types_1.ApiError(500, 'Failed to disable biometric authentication');
        }
    }
    static async getBiometricStatus(userId, deviceId) {
        try {
            const credential = await database_1.prisma.biometricCredential.findUnique({
                where: {
                    userId_deviceId: {
                        userId,
                        deviceId
                    }
                }
            });
            return {
                isEnabled: (credential === null || credential === void 0 ? void 0 : credential.isActive) || false,
                biometricType: credential === null || credential === void 0 ? void 0 : credential.biometricType,
                lastUsed: (credential === null || credential === void 0 ? void 0 : credential.lastUsed) || undefined
            };
        }
        catch (error) {
            return { isEnabled: false };
        }
    }
    // Helper methods
    static generateAccessToken(userId, email) {
        const jwtSecret = process.env.JWT_SECRET;
        if (!jwtSecret) {
            throw new Error('JWT_SECRET environment variable is not set');
        }
        const options = { expiresIn: this.JWT_ACCESS_EXPIRES_IN };
        return jsonwebtoken_1.default.sign({ id: userId, email, type: 'access' }, jwtSecret, options);
    }
    static generateRefreshToken(userId, email, deviceId) {
        const jwtSecret = process.env.JWT_SECRET;
        if (!jwtSecret) {
            throw new Error('JWT_SECRET environment variable is not set');
        }
        const payload = { id: userId, type: 'refresh' };
        if (email)
            payload.email = email;
        if (deviceId)
            payload.deviceId = deviceId;
        const options = { expiresIn: this.JWT_REFRESH_EXPIRES_IN };
        return jsonwebtoken_1.default.sign(payload, jwtSecret, options);
    }
    static hashToken(token) {
        return crypto_1.default.createHash('sha256').update(token).digest('hex');
    }
    static async createSession(userId, deviceId, accessToken, refreshToken, deviceInfo) {
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7); // 7 days
        console.log('🔐 [CreateSession] Creating session for user:', userId, 'device:', deviceId);
        // Clean up old sessions for this user-device combination first
        await database_1.prisma.userSession.deleteMany({
            where: {
                userId,
                deviceId,
                isActive: true
            }
        });
        console.log('🧹 [CreateSession] Cleaned up old sessions for device:', deviceId);
        // Also clean up any expired sessions for this user
        await database_1.prisma.userSession.deleteMany({
            where: {
                userId,
                expiresAt: { lt: new Date() }
            }
        });
        console.log('🗑️ [CreateSession] Cleaned up expired sessions for user:', userId);
        // Create new session
        const session = await database_1.prisma.userSession.create({
            data: {
                userId,
                deviceId,
                deviceName: deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.deviceName,
                deviceType: deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.deviceType,
                accessTokenHash: this.hashToken(accessToken),
                refreshTokenHash: this.hashToken(refreshToken),
                expiresAt,
                ipAddress: deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.ipAddress,
                userAgent: deviceInfo === null || deviceInfo === void 0 ? void 0 : deviceInfo.userAgent
            }
        });
        console.log('✅ [CreateSession] Created new session:', session.id);
    }
    static async handleFailedLogin(userId, ipAddress) {
        const user = await database_1.prisma.user.findUnique({ where: { id: userId } });
        if (!user)
            return;
        const failedAttempts = user.failedLoginAttempts + 1;
        const updates = { failedLoginAttempts: failedAttempts };
        if (failedAttempts >= this.MAX_FAILED_ATTEMPTS) {
            updates.lockedUntil = new Date(Date.now() + this.LOCK_TIME);
            await this.logSecurityEvent(userId, 'account_locked', 'high', `Account locked after ${failedAttempts} failed attempts`, ipAddress);
        }
        else {
            await this.logSecurityEvent(userId, 'login_failed', 'medium', `Failed login attempt ${failedAttempts}`, ipAddress);
        }
        await database_1.prisma.user.update({
            where: { id: userId },
            data: updates
        });
    }
    static async cleanupUserSessions(userId) {
        try {
            console.log('🧹 [CleanupSessions] Starting cleanup for user:', userId);
            // Delete all expired sessions
            const expiredCount = await database_1.prisma.userSession.deleteMany({
                where: {
                    userId,
                    expiresAt: { lt: new Date() }
                }
            });
            console.log('🗑️ [CleanupSessions] Deleted expired sessions:', expiredCount.count);
            // Keep only the most recent 2 active sessions per user
            const allSessions = await database_1.prisma.userSession.findMany({
                where: { userId, isActive: true },
                orderBy: { lastActive: 'desc' }
            });
            if (allSessions.length > 2) {
                const sessionsToDelete = allSessions.slice(2);
                const deleteIds = sessionsToDelete.map(s => s.id);
                const oldCount = await database_1.prisma.userSession.deleteMany({
                    where: {
                        id: { in: deleteIds }
                    }
                });
                console.log('🚮 [CleanupSessions] Deleted old sessions:', oldCount.count);
            }
            console.log('✅ [CleanupSessions] Cleanup completed for user:', userId);
        }
        catch (error) {
            console.error('🚨 [CleanupSessions] Error:', error);
            throw error;
        }
    }
    static async logSecurityEvent(userId, eventType, severity, description, ipAddress, userAgent) {
        try {
            await database_1.prisma.securityEvent.create({
                data: {
                    userId,
                    eventType,
                    severity,
                    description,
                    ipAddress,
                    userAgent
                }
            });
        }
        catch (error) {
            console.error('Failed to log security event:', error);
        }
    }
    static async getUserProfile(userId) {
        const user = await database_1.prisma.user.findUnique({
            where: { id: userId }
        });
        if (!user) {
            throw new types_1.ApiError(404, 'User not found');
        }
        return this.sanitizeUser(user);
    }
    static async updateUserProfile(userId, data) {
        const user = await database_1.prisma.user.update({
            where: { id: userId },
            data: Object.assign(Object.assign(Object.assign(Object.assign({}, (data.name && { name: data.name })), (data.bio && { bio: data.bio })), (data.preferences && { preferences: data.preferences })), { updatedAt: new Date() })
        });
        return this.sanitizeUser(user);
    }
    static validatePassword(password) {
        if (password.length < 8) {
            throw new types_1.ApiError(400, 'Password minimal 8 karakter');
        }
        if (!/(?=.*[a-z])/.test(password)) {
            throw new types_1.ApiError(400, 'Password harus mengandung huruf kecil');
        }
        if (!/(?=.*[A-Z])/.test(password)) {
            throw new types_1.ApiError(400, 'Password harus mengandung huruf besar');
        }
        if (!/(?=.*\d)/.test(password)) {
            throw new types_1.ApiError(400, 'Password harus mengandung angka');
        }
    }
    static sanitizeUser(user) {
        const { passwordHash, verificationToken } = user, sanitized = __rest(user, ["passwordHash", "verificationToken"]);
        // Map displayName to name for API consistency
        if (user.displayName) {
            sanitized.name = user.displayName;
        }
        return sanitized;
    }
}
exports.ProductionAuthService = ProductionAuthService;
ProductionAuthService.SALT_ROUNDS = parseInt(process.env.BCRYPT_ROUNDS || '12');
ProductionAuthService.JWT_SECRET = process.env.JWT_SECRET;
ProductionAuthService.JWT_ACCESS_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '15m';
ProductionAuthService.JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '7d';
ProductionAuthService.MAX_FAILED_ATTEMPTS = 5;
ProductionAuthService.LOCK_TIME = 15 * 60 * 1000; // 15 minutes
//# sourceMappingURL=productionAuthService.js.map