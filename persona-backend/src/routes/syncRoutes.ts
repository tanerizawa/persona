import { Router, Request, Response, NextFunction } from 'express';
import { authenticateToken } from '../middlewares/auth';
import { SyncService } from '../services/syncService';
import { SyncRequest, BackupRequest } from '../types';

const router = Router();

// Update sync status
router.post('/status', authenticateToken, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'User not authenticated',
        timestamp: new Date().toISOString()
      });
      return;
    }

    const { deviceId, dataHash, syncVersion }: SyncRequest = req.body;

    if (!deviceId || !dataHash) {
      res.status(400).json({
        success: false,
        error: 'Device ID and data hash are required',
        timestamp: new Date().toISOString()
      });
      return;
    }

    const syncStatus = await SyncService.updateSyncStatus(
      req.user.userId,
      deviceId,
      dataHash,
      syncVersion
    );

    res.status(200).json({
      success: true,
      data: { syncStatus },
      message: 'Sync status updated successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    next(error);
  }
});

// Get sync status
router.get('/status/:deviceId', authenticateToken, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
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

    const syncStatus = await SyncService.getSyncStatus(req.user.userId, deviceId);

    res.status(200).json({
      success: true,
      data: { syncStatus },
      message: 'Sync status retrieved successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    next(error);
  }
});

// Create backup
router.post('/backup', authenticateToken, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'User not authenticated',
        timestamp: new Date().toISOString()
      });
      return;
    }

    const { encryptedData, checksum }: BackupRequest = req.body;

    if (!encryptedData || !checksum) {
      res.status(400).json({
        success: false,
        error: 'Encrypted data and checksum are required',
        timestamp: new Date().toISOString()
      });
      return;
    }

    const backup = await SyncService.createBackup(req.user.userId, encryptedData, checksum);

    res.status(201).json({
      success: true,
      data: { backup },
      message: 'Backup created successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    next(error);
  }
});

// Get latest backup
router.get('/backup/latest', authenticateToken, async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'User not authenticated',
        timestamp: new Date().toISOString()
      });
      return;
    }

    const backup = await SyncService.getLatestBackup(req.user.userId);

    res.status(200).json({
      success: true,
      data: { backup },
      message: backup ? 'Latest backup retrieved successfully' : 'No backup found',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    next(error);
  }
});

export default router;
