"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SyncService = void 0;
const database_1 = require("../config/database");
class SyncService {
    static async updateSyncStatus(userId, deviceId, dataHash, syncVersion) {
        // Update or create sync status
        const syncStatus = await database_1.prisma.userSyncStatus.upsert({
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
    static async getSyncStatus(userId, deviceId) {
        const syncStatus = await database_1.prisma.userSyncStatus.findUnique({
            where: {
                userId_deviceId: {
                    userId,
                    deviceId
                }
            }
        });
        return syncStatus;
    }
    static async getAllSyncStatuses(userId) {
        const syncStatuses = await database_1.prisma.userSyncStatus.findMany({
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
    static async deactivateDevice(userId, deviceId) {
        const syncStatus = await database_1.prisma.userSyncStatus.update({
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
    static async createBackup(userId, encryptedData, checksum) {
        // Delete old backups to keep only the latest 5
        const existingBackups = await database_1.prisma.userBackup.findMany({
            where: { userId },
            orderBy: { backupDate: 'desc' },
            skip: 4 // Keep latest 4, will add 1 more
        });
        if (existingBackups.length > 0) {
            await database_1.prisma.userBackup.deleteMany({
                where: {
                    id: {
                        in: existingBackups.map((backup) => backup.id)
                    }
                }
            });
        }
        // Create new backup
        const backup = await database_1.prisma.userBackup.create({
            data: {
                userId,
                encryptedData,
                checksum,
                dataSize: encryptedData.length
            }
        });
        return backup;
    }
    static async getLatestBackup(userId) {
        const backup = await database_1.prisma.userBackup.findFirst({
            where: { userId },
            orderBy: { backupDate: 'desc' }
        });
        return backup;
    }
    static async getAllBackups(userId) {
        const backups = await database_1.prisma.userBackup.findMany({
            where: { userId },
            orderBy: { backupDate: 'desc' },
            take: 10 // Return only latest 10 backups
        });
        return backups;
    }
    static async deleteBackup(userId, backupId) {
        try {
            await database_1.prisma.userBackup.delete({
                where: {
                    id: backupId,
                    userId // Ensure user can only delete their own backups
                }
            });
            return true;
        }
        catch (error) {
            return false;
        }
    }
    static async validateDataIntegrity(dataHash, expectedChecksum) {
        // Simple hash validation - in production, use crypto.createHash
        return dataHash === expectedChecksum;
    }
}
exports.SyncService = SyncService;
//# sourceMappingURL=syncService.js.map