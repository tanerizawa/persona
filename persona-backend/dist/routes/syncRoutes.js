"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = require("../middlewares/auth");
const syncService_1 = require("../services/syncService");
const router = (0, express_1.Router)();
// Update sync status
router.post('/status', auth_1.authenticateToken, async (req, res, next) => {
    try {
        if (!req.user) {
            res.status(401).json({
                success: false,
                error: 'User not authenticated',
                timestamp: new Date().toISOString()
            });
            return;
        }
        const { deviceId, dataHash, syncVersion } = req.body;
        if (!deviceId || !dataHash) {
            res.status(400).json({
                success: false,
                error: 'Device ID and data hash are required',
                timestamp: new Date().toISOString()
            });
            return;
        }
        const syncStatus = await syncService_1.SyncService.updateSyncStatus(req.user.userId, deviceId, dataHash, syncVersion);
        res.status(200).json({
            success: true,
            data: { syncStatus },
            message: 'Sync status updated successfully',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        next(error);
    }
});
// Get sync status
router.get('/status/:deviceId', auth_1.authenticateToken, async (req, res, next) => {
    try {
        if (!req.user) {
            res.status(401).json({
                success: false,
                error: 'User not authenticated',
                timestamp: new Date().toISOString()
            });
            return;
        }
        const { deviceId } = req.params;
        if (!deviceId) {
            res.status(400).json({
                success: false,
                error: 'Device ID is required',
                timestamp: new Date().toISOString()
            });
            return;
        }
        const syncStatus = await syncService_1.SyncService.getSyncStatus(req.user.userId, deviceId);
        res.status(200).json({
            success: true,
            data: { syncStatus },
            message: 'Sync status retrieved successfully',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        next(error);
    }
});
// Create backup
router.post('/backup', auth_1.authenticateToken, async (req, res, next) => {
    try {
        if (!req.user) {
            res.status(401).json({
                success: false,
                error: 'User not authenticated',
                timestamp: new Date().toISOString()
            });
            return;
        }
        const { encryptedData, checksum } = req.body;
        if (!encryptedData || !checksum) {
            res.status(400).json({
                success: false,
                error: 'Encrypted data and checksum are required',
                timestamp: new Date().toISOString()
            });
            return;
        }
        const backup = await syncService_1.SyncService.createBackup(req.user.userId, encryptedData, checksum);
        res.status(201).json({
            success: true,
            data: { backup },
            message: 'Backup created successfully',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        next(error);
    }
});
// Get latest backup
router.get('/backup/latest', auth_1.authenticateToken, async (req, res, next) => {
    try {
        if (!req.user) {
            res.status(401).json({
                success: false,
                error: 'User not authenticated',
                timestamp: new Date().toISOString()
            });
            return;
        }
        const backup = await syncService_1.SyncService.getLatestBackup(req.user.userId);
        res.status(200).json({
            success: true,
            data: { backup },
            message: backup ? 'Latest backup retrieved successfully' : 'No backup found',
            timestamp: new Date().toISOString()
        });
    }
    catch (error) {
        next(error);
    }
});
exports.default = router;
//# sourceMappingURL=syncRoutes.js.map