"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const authController_1 = require("../controllers/authController");
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
const authController = new authController_1.AuthController();
// Public routes
router.post('/register', (req, res) => authController.register(req, res));
router.post('/login', (req, res) => authController.login(req, res));
router.post('/refresh', (req, res) => authController.refreshToken(req, res));
// Protected routes
router.post('/logout', authMiddleware_1.authMiddleware, (req, res) => authController.logout(req, res));
router.get('/profile', authMiddleware_1.authMiddleware, (req, res) => authController.getProfile(req, res));
router.put('/profile', authMiddleware_1.authMiddleware, (req, res) => authController.updateProfile(req, res));
// Biometric authentication routes
router.post('/biometric/setup', authMiddleware_1.authMiddleware, (req, res) => authController.setupBiometric(req, res));
router.post('/biometric/verify', authMiddleware_1.authMiddleware, (req, res) => authController.verifyBiometric(req, res));
router.post('/biometric/disable', authMiddleware_1.authMiddleware, (req, res) => authController.disableBiometric(req, res));
exports.default = router;
//# sourceMappingURL=authRoutes.js.map