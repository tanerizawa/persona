import { Router } from 'express';
import { ChatController } from '../controllers/chatController';
import { authMiddleware } from '../middlewares/authMiddleware';

const router = Router();
const chatController = new ChatController();

// All chat routes require authentication
router.use(authMiddleware);

// Chat endpoints
router.post('/send', (req, res) => chatController.sendMessage(req, res));
router.get('/conversations', (req, res) => chatController.getUserConversations(req, res));
router.get('/conversations/:conversationId', (req, res) => chatController.getConversationHistory(req, res));
router.delete('/conversations/:conversationId', (req, res) => chatController.deleteConversation(req, res));
router.delete('/conversations', (req, res) => chatController.clearUserConversations(req, res));

export default router;
