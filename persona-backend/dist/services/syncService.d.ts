import { UserSyncStatus, UserBackup } from '../types';
export declare class SyncService {
    static updateSyncStatus(userId: string, deviceId: string, dataHash: string, syncVersion?: number): Promise<UserSyncStatus>;
    static getSyncStatus(userId: string, deviceId: string): Promise<UserSyncStatus | null>;
    static getAllSyncStatuses(userId: string): Promise<UserSyncStatus[]>;
    static deactivateDevice(userId: string, deviceId: string): Promise<UserSyncStatus | null>;
    static createBackup(userId: string, encryptedData: string, checksum: string): Promise<UserBackup>;
    static getLatestBackup(userId: string): Promise<UserBackup | null>;
    static getAllBackups(userId: string): Promise<UserBackup[]>;
    static deleteBackup(userId: string, backupId: string): Promise<boolean>;
    static validateDataIntegrity(dataHash: string, expectedChecksum: string): Promise<boolean>;
}
