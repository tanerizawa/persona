import { Request, Response, NextFunction } from 'express';
import { JwtPayload } from '../types';
declare global {
    namespace Express {
        interface Request {
            user?: JwtPayload;
        }
    }
}
export declare const authenticateToken: (req: Request, res: Response, next: NextFunction) => void;
