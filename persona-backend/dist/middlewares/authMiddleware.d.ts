import { Request, Response, NextFunction } from 'express';
import { AuthenticatedUser } from '../types/index';
export interface AuthenticatedRequest extends Request {
    user?: AuthenticatedUser;
}
export declare const authMiddleware: (req: AuthenticatedRequest, res: Response, next: NextFunction) => Promise<void>;
export declare const optionalAuthMiddleware: (req: AuthenticatedRequest, res: Response, next: NextFunction) => Promise<void>;
