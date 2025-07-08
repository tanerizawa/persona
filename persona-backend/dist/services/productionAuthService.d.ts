import { LoginRequest, RegisterRequest } from '../types';
export declare class ProductionAuthService {
    private static readonly SALT_ROUNDS;
    private static readonly JWT_SECRET;
    private static readonly JWT_ACCESS_EXPIRES_IN;
    private static readonly JWT_REFRESH_EXPIRES_IN;
    private static readonly MAX_FAILED_ATTEMPTS;
    private static readonly LOCK_TIME;
    static register(data: RegisterRequest & {
        deviceId: string;
        deviceInfo?: any;
    }): Promise<{
        user: any;
        accessToken: string;
        refreshToken: string;
        requiresVerification: boolean;
    }>;
    static login(data: LoginRequest & {
        deviceId: string;
        deviceInfo?: any;
    }): Promise<{
        user: any;
        accessToken: string;
        refreshToken: string;
    }>;
    static refreshToken(refreshToken: string): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    static logout(userId: string, deviceId: string): Promise<void>;
    static verifyEmail(token: string): Promise<void>;
    static setupBiometric(userId: string, deviceId: string, biometricHash: string, biometricType?: string): Promise<void>;
    static verifyBiometric(userId: string, deviceId: string, biometricHash: string): Promise<boolean>;
    static disableBiometric(userId: string, deviceId: string): Promise<void>;
    static getBiometricStatus(userId: string, deviceId: string): Promise<{
        isEnabled: boolean;
        biometricType?: string;
        lastUsed?: Date;
    }>;
    private static generateAccessToken;
    private static generateRefreshToken;
    private static hashToken;
    private static createSession;
    private static handleFailedLogin;
    private static logSecurityEvent;
    static getUserProfile(userId: string): Promise<any>;
    static updateUserProfile(userId: string, data: {
        name?: string;
        bio?: string;
        preferences?: any;
    }): Promise<any>;
    private static validatePassword;
    private static sanitizeUser;
}
