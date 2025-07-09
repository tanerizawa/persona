import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { authMiddleware } from '../middlewares/authMiddleware';

const router = Router();
const authController = new AuthController();

// Public routes
router.post('/register', (req, res) => authController.register(req, res));
router.post('/login', (req, res) => authController.login(req, res));
router.post('/refresh', (req, res) => authController.refreshToken(req, res));

// Protected routes
router.post('/logout', authMiddleware, (req, res) => authController.logout(req, res));
router.get('/profile', authMiddleware, (req, res) => authController.getProfile(req, res));
router.put('/profile', authMiddleware, (req, res) => authController.updateProfile(req, res));
router.post('/cleanup-sessions', authMiddleware, (req, res) => authController.cleanupSessions(req, res));

// Biometric authentication routes
router.post('/biometric/setup', authMiddleware, (req, res) => authController.setupBiometric(req, res));
router.post('/biometric/verify', authMiddleware, (req, res) => authController.verifyBiometric(req, res));
router.post('/biometric/disable', authMiddleware, (req, res) => authController.disableBiometric(req, res));

export default router;
