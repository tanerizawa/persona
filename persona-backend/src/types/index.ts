export class ApiError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;

  constructor(statusCode: number, message: string, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  timestamp: string;
}

export interface JwtPayload {
  id: string;
  /**
   * Alias for `id` used by middleware and controllers for backward compatibility
   */
  userId: string;
  email: string;
  iat?: number;
  exp?: number;
}

export interface AuthenticatedUser extends JwtPayload {
  userId: string; // Alias for id for backward compatibility
}

export interface User {
  id: string;
  email: string;
  createdAt: Date;
  lastSync: Date;
  deviceCount: number;
}

export interface UserSyncStatus {
  id: string;
  userId: string;
  deviceId: string;
  lastSyncTimestamp: Date;
  syncVersion: number;
  dataHash?: string | null;
  isActive: boolean;
}

export interface AiScript {
  id: string;
  scriptName: string;
  version: string;
  scriptContent: string; // JSON string stored in database
  isActive: boolean;
  createdAt: Date;
}

export interface UserBackup {
  id: string;
  userId: string;
  encryptedData?: string | null;
  backupDate: Date;
  dataSize?: number | null;
  checksum?: string | null;
}


export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
  name: string;
}

export interface SyncRequest {
  deviceId: string;
  dataHash: string;
  syncVersion?: number;
}

export interface BackupRequest {
  encryptedData: string;
  checksum: string;
}
