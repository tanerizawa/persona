"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const productionAuthService_1 = require("../services/productionAuthService");
const crypto_1 = __importDefault(require("crypto"));
class AuthController {
    async register(req, res) {
        try {
            const { email, password, name, deviceId } = req.body;
            if (!email || !password || !name) {
                res.status(400).json({
                    success: false,
                    error: 'Missing required fields',
                    message: 'Email, password, and name are required'
                });
                return;
            }
            // Generate deviceId if not provided
            const finalDeviceId = deviceId || crypto_1.default.randomUUID();
            const result = await productionAuthService_1.ProductionAuthService.register({
                email,
                password,
                name,
                deviceId: finalDeviceId
            });
            res.status(201).json({
                success: true,
                accessToken: result.accessToken,
                refreshToken: result.refreshToken,
                user: {
                    id: result.user.id,
                    email: result.user.email,
                    name: result.user.name,
                    bio: result.user.bio,
                    preferences: result.user.preferences,
                    createdAt: result.user.createdAt,
                    updatedAt: result.user.updatedAt
                }
            });
        }
        catch (error) {
            console.error('Registration error:', error);
            // Handle ApiError with specific status codes
            if (error.statusCode) {
                // Already using correct 409 status code for duplicate emails
                if (error.statusCode === 409) {
                    res.status(409).json({
                        success: false,
                        error: 'User already exists',
                        message: 'An account with this email already exists'
                    });
                    return;
                }
                res.status(error.statusCode).json({
                    success: false,
                    error: error.message,
                    message: error.message
                });
                return;
            }
            if (error.message.includes('already exists')) {
                res.status(409).json({
                    success: false,
                    error: 'User already exists',
                    message: 'An account with this email already exists'
                });
                return;
            }
            res.status(500).json({
                success: false,
                error: 'Registration failed',
                message: 'Internal server error'
            });
        }
    }
    async login(req, res) {
        try {
            const { email, password, deviceId } = req.body;
            if (!email || !password) {
                res.status(400).json({
                    success: false,
                    error: 'Missing credentials',
                    message: 'Email and password are required'
                });
                return;
            }
            // Generate deviceId if not provided
            const finalDeviceId = deviceId || crypto_1.default.randomUUID();
            const result = await productionAuthService_1.ProductionAuthService.login({
                email,
                password,
                deviceId: finalDeviceId
            });
            res.json({
                success: true,
                accessToken: result.accessToken,
                refreshToken: result.refreshToken,
                user: {
                    id: result.user.id,
                    email: result.user.email,
                    name: result.user.name,
                    bio: result.user.bio,
                    preferences: result.user.preferences,
                    createdAt: result.user.createdAt,
                    updatedAt: result.user.updatedAt
                }
            });
        }
        catch (error) {
            console.error('Login error:', error);
            // Handle ApiError with specific status codes
            if (error.statusCode) {
                res.status(error.statusCode).json({
                    success: false,
                    error: error.message,
                    message: error.message
                });
                return;
            }
            if (error.message.includes('Invalid credentials')) {
                res.status(401).json({
                    success: false,
                    error: 'Invalid credentials',
                    message: 'Email or password is incorrect'
                });
                return;
            }
            if (error.message.includes('Account locked')) {
                res.status(423).json({
                    success: false,
                    error: 'Account locked',
                    message: 'Account has been locked due to too many failed attempts'
                });
                return;
            }
            res.status(500).json({
                success: false,
                error: 'Login failed',
                message: 'Internal server error'
            });
        }
    }
    async logout(req, res) {
        var _a, _b;
        try {
            const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
            const deviceId = req.headers['x-device-id'] || ((_b = req.body) === null || _b === void 0 ? void 0 : _b.deviceId);
            if (userId && deviceId) {
                await productionAuthService_1.ProductionAuthService.logout(userId, deviceId);
            }
            res.json({
                success: true,
                message: 'Logged out successfully'
            });
        }
        catch (error) {
            console.error('Logout error:', error);
            res.status(500).json({
                success: false,
                error: 'Logout failed',
                message: 'Internal server error'
            });
        }
    }
    async refreshToken(req, res) {
        try {
            const { refreshToken, deviceId } = req.body;
            if (!refreshToken) {
                res.status(400).json({
                    success: false,
                    error: 'Missing refresh token',
                    message: 'Refresh token is required'
                });
                return;
            }
            const result = await productionAuthService_1.ProductionAuthService.refreshToken(refreshToken, deviceId);
            res.json({
                success: true,
                accessToken: result.accessToken,
                refreshToken: result.refreshToken
            });
        }
        catch (error) {
            console.error('Token refresh error:', error);
            if (error.message.includes('Invalid') || error.message.includes('expired')) {
                res.status(401).json({
                    success: false,
                    error: 'Invalid refresh token',
                    message: 'Refresh token is invalid or expired'
                });
                return;
            }
            res.status(500).json({
                success: false,
                error: 'Token refresh failed',
                message: 'Internal server error'
            });
        }
    }
    async getProfile(req, res) {
        var _a;
        try {
            const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
            if (!userId) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'User not authenticated'
                });
                return;
            }
            const user = await productionAuthService_1.ProductionAuthService.getUserProfile(userId);
            res.json({
                success: true,
                user: {
                    id: user.id,
                    email: user.email,
                    name: user.name,
                    bio: user.bio,
                    preferences: user.preferences,
                    createdAt: user.createdAt,
                    updatedAt: user.updatedAt
                }
            });
        }
        catch (error) {
            console.error('Get profile error:', error);
            res.status(500).json({
                success: false,
                error: 'Failed to get profile',
                message: 'Internal server error'
            });
        }
    }
    async updateProfile(req, res) {
        var _a;
        try {
            const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.userId;
            const { name, bio, preferences } = req.body;
            if (!userId) {
                res.status(401).json({
                    success: false,
                    error: 'Unauthorized',
                    message: 'User not authenticated'
                });
                return;
            }
            const updatedUser = await productionAuthService_1.ProductionAuthService.updateUserProfile(userId, {
                name,
                bio,
                preferences
            });
            res.json({
                success: true,
                user: {
                    id: updatedUser.id,
                    email: updatedUser.email,
                    name: updatedUser.name,
                    bio: updatedUser.bio,
                    preferences: updatedUser.preferences,
                    createdAt: updatedUser.createdAt,
                    updatedAt: updatedUser.updatedAt
                }
            });
        }
        catch (error) {
            console.error('Update profile error:', error);
            res.status(500).json({
                success: false,
                error: 'Failed to update profile',
                message: 'Internal server error'
            });
        }
    }
    async setupBiometric(req, res) {
        try {
            const userId = req.user.id;
            const { deviceId, biometricHash, biometricType } = req.body;
            if (!deviceId || !biometricHash) {
                res.status(400).json({
                    success: false,
                    error: 'Missing required fields',
                    message: 'Device ID and biometric hash are required'
                });
                return;
            }
            await productionAuthService_1.ProductionAuthService.setupBiometric(userId, deviceId, biometricHash, biometricType);
            res.json({
                success: true,
                message: 'Biometric authentication setup successfully'
            });
        }
        catch (error) {
            console.error('Setup biometric error:', error);
            res.status(500).json({
                success: false,
                error: 'Setup biometric failed',
                message: 'Internal server error'
            });
        }
    }
    async verifyBiometric(req, res) {
        try {
            const userId = req.user.id;
            const { deviceId, biometricHash } = req.body;
            if (!deviceId || !biometricHash) {
                res.status(400).json({
                    success: false,
                    error: 'Missing required fields',
                    message: 'Device ID and biometric hash are required'
                });
                return;
            }
            const isValid = await productionAuthService_1.ProductionAuthService.verifyBiometric(userId, deviceId, biometricHash);
            if (isValid) {
                res.json({
                    success: true,
                    message: 'Biometric authentication successful'
                });
            }
            else {
                res.status(401).json({
                    success: false,
                    error: 'Biometric verification failed',
                    message: 'Invalid biometric credentials'
                });
            }
        }
        catch (error) {
            console.error('Verify biometric error:', error);
            res.status(500).json({
                success: false,
                error: 'Biometric verification failed',
                message: 'Internal server error'
            });
        }
    }
    async disableBiometric(req, res) {
        try {
            const userId = req.user.id;
            const { deviceId } = req.body;
            if (!deviceId) {
                res.status(400).json({
                    success: false,
                    error: 'Missing device ID',
                    message: 'Device ID is required'
                });
                return;
            }
            await productionAuthService_1.ProductionAuthService.disableBiometric(userId, deviceId);
            res.json({
                success: true,
                message: 'Biometric authentication disabled successfully'
            });
        }
        catch (error) {
            console.error('Disable biometric error:', error);
            res.status(500).json({
                success: false,
                error: 'Disable biometric failed',
                message: 'Internal server error'
            });
        }
    }
    async cleanupSessions(req, res) {
        var _a;
        try {
            const userId = (_a = req.user) === null || _a === void 0 ? void 0 : _a.id;
            if (!userId) {
                res.status(401).json({
                    success: false,
                    error: 'User not authenticated',
                    message: 'Authentication required'
                });
                return;
            }
            await productionAuthService_1.ProductionAuthService.cleanupUserSessions(userId);
            res.json({
                success: true,
                message: 'Old sessions cleaned up successfully'
            });
        }
        catch (error) {
            console.error('Cleanup sessions error:', error);
            res.status(500).json({
                success: false,
                error: 'Session cleanup failed',
                message: 'Internal server error'
            });
        }
    }
}
exports.AuthController = AuthController;
//# sourceMappingURL=authController.js.map