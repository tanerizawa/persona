import { prisma } from '../config/database';
import { ApiError, UserSyncStatus, UserBackup } from '../types';

export class SyncService {
  static async updateSyncStatus(
    userId: string,
    deviceId: string,
    dataHash: string,
    syncVersion?: number
  ): Promise<UserSyncStatus> {
    // Update or create sync status
    const syncStatus = await prisma.userSyncStatus.upsert({
      where: {
        userId_deviceId: {
          userId,
          deviceId
        }
      },
      update: {
        lastSyncTimestamp: new Date(),
        dataHash,
        syncVersion: syncVersion || 1,
        isActive: true
      },
      create: {
        userId,
        deviceId,
        dataHash,
        syncVersion: syncVersion || 1,
        isActive: true
      }
    });

    return syncStatus;
  }

  static async getSyncStatus(userId: string, deviceId: string): Promise<UserSyncStatus | null> {
    const syncStatus = await prisma.userSyncStatus.findUnique({
      where: {
        userId_deviceId: {
          userId,
          deviceId
        }
      }
    });

    return syncStatus;
  }

  static async getAllSyncStatuses(userId: string): Promise<UserSyncStatus[]> {
    const syncStatuses = await prisma.userSyncStatus.findMany({
      where: {
        userId,
        isActive: true
      },
      orderBy: {
        lastSyncTimestamp: 'desc'
      }
    });

    return syncStatuses;
  }

  static async deactivateDevice(userId: string, deviceId: string): Promise<UserSyncStatus | null> {
    const syncStatus = await prisma.userSyncStatus.update({
      where: {
        userId_deviceId: {
          userId,
          deviceId
        }
      },
      data: {
        isActive: false
      }
    });

    return syncStatus;
  }

  static async createBackup(
    userId: string,
    encryptedData: string,
    checksum: string
  ): Promise<UserBackup> {
    // Delete old backups to keep only the latest 5
    const existingBackups = await prisma.userBackup.findMany({
      where: { userId },
      orderBy: { backupDate: 'desc' },
      skip: 4 // Keep latest 4, will add 1 more
    });

    if (existingBackups.length > 0) {
      await prisma.userBackup.deleteMany({
        where: {
          id: {
            in: existingBackups.map((backup: any) => backup.id)
          }
        }
      });
    }

    // Create new backup
    const backup = await prisma.userBackup.create({
      data: {
        userId,
        encryptedData,
        checksum,
        dataSize: encryptedData.length
      }
    });

    return backup;
  }

  static async getLatestBackup(userId: string): Promise<UserBackup | null> {
    const backup = await prisma.userBackup.findFirst({
      where: { userId },
      orderBy: { backupDate: 'desc' }
    });

    return backup;
  }

  static async getAllBackups(userId: string): Promise<UserBackup[]> {
    const backups = await prisma.userBackup.findMany({
      where: { userId },
      orderBy: { backupDate: 'desc' },
      take: 10 // Return only latest 10 backups
    });

    return backups;
  }

  static async deleteBackup(userId: string, backupId: string): Promise<boolean> {
    try {
      await prisma.userBackup.delete({
        where: {
          id: backupId,
          userId // Ensure user can only delete their own backups
        }
      });
      return true;
    } catch (error) {
      return false;
    }
  }

  static async validateDataIntegrity(
    dataHash: string,
    expectedChecksum: string
  ): Promise<boolean> {
    // Simple hash validation - in production, use crypto.createHash
    return dataHash === expectedChecksum;
  }
}
