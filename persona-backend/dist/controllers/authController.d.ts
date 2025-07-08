import { Request, Response } from 'express';
export declare class AuthController {
    register(req: Request, res: Response): Promise<void>;
    login(req: Request, res: Response): Promise<void>;
    logout(req: Request, res: Response): Promise<void>;
    refreshToken(req: Request, res: Response): Promise<void>;
    getProfile(req: Request, res: Response): Promise<void>;
    updateProfile(req: Request, res: Response): Promise<void>;
    setupBiometric(req: Request, res: Response): Promise<void>;
    verifyBiometric(req: Request, res: Response): Promise<void>;
    disableBiometric(req: Request, res: Response): Promise<void>;
}
