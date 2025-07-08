import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { ApiError, JwtPayload } from '../types';

declare global {
  namespace Express {
    interface Request {
      user?: JwtPayload;
    }
  }
}

export const authenticateToken = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

  if (!token) {
    const error = new ApiError(401, 'Access token required');
    return next(error);
  }

  const jwtSecret = process.env.JWT_SECRET;
  if (!jwtSecret) {
    const error = new ApiError(500, 'JWT secret not configured');
    return next(error);
  }

  jwt.verify(token, jwtSecret, (err, decoded) => {
    if (err) {
      const error = new ApiError(403, 'Invalid or expired token');
      return next(error);
    }

    req.user = decoded as JwtPayload;
    next();
  });
};
