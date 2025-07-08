import { Request, Response, NextFunction } from 'express';
import { ApiError, ApiResponse } from '../types';
export declare const errorHandler: (err: ApiError, req: Request, res: Response<ApiResponse>, next: NextFunction) => void;
