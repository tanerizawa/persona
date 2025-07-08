"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const chatController_1 = require("../controllers/chatController");
const authMiddleware_1 = require("../middlewares/authMiddleware");
const router = (0, express_1.Router)();
const chatController = new chatController_1.ChatController();
// All chat routes require authentication
router.use(authMiddleware_1.authMiddleware);
// Chat endpoints
router.post('/send', (req, res) => chatController.sendMessage(req, res));
router.get('/conversations', (req, res) => chatController.getUserConversations(req, res));
router.get('/conversations/:conversationId', (req, res) => chatController.getConversationHistory(req, res));
router.delete('/conversations/:conversationId', (req, res) => chatController.deleteConversation(req, res));
router.delete('/conversations', (req, res) => chatController.clearUserConversations(req, res));
exports.default = router;
//# sourceMappingURL=chatRoutes.js.map