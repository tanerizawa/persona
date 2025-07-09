import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { JwtPayload, AuthenticatedUser } from '../types/index';
import { prisma } from '../config/database';
import crypto from 'crypto';

export interface AuthenticatedRequest extends Request {
  user?: AuthenticatedUser;
}

export const authMiddleware = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        error: 'Authentication required',
        message: 'No valid authorization token provided'
      });
      return;
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    const jwtSecret = process.env.JWT_SECRET;
    
    if (!jwtSecret) {
      console.error('JWT_SECRET not configured');
      res.status(500).json({
        success: false,
        error: 'Server configuration error',
        message: 'Authentication service not properly configured'
      });
      return;
    }

    try {
      const decoded = jwt.verify(token, jwtSecret) as JwtPayload;
      
      // Check if session is still active in database
      const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
      const activeSession = await prisma.userSession.findFirst({
        where: {
          userId: decoded.id,
          accessTokenHash: tokenHash,
          isActive: true,
          expiresAt: { gte: new Date() }
        }
      });

      if (!activeSession) {
        res.status(401).json({
          success: false,
          error: 'Session invalid',
          message: 'Session has been terminated or expired'
        });
        return;
      }
      
      // Add user info to request object
      req.user = {
        id: decoded.id,
        userId: decoded.id, // For backward compatibility
        email: decoded.email,
        iat: decoded.iat,
        exp: decoded.exp
      } as AuthenticatedUser;
      
      next();
    } catch (jwtError: any) {
      if (jwtError.name === 'TokenExpiredError') {
        res.status(401).json({
          success: false,
          error: 'Token expired',
          message: 'Access token has expired. Please refresh your token.'
        });
        return;
      }
      
      if (jwtError.name === 'JsonWebTokenError') {
        res.status(401).json({
          success: false,
          error: 'Invalid token',
          message: 'The provided token is invalid'
        });
        return;
      }
      
      res.status(401).json({
        success: false,
        error: 'Authentication failed',
        message: 'Token verification failed'
      });
      return;
    }
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({
      success: false,
      error: 'Authentication error',
      message: 'Internal server error during authentication'
    });
    return;
  }
};

export const optionalAuthMiddleware = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // No auth header, continue without user info
      next();
      return;
    }

    const token = authHeader.substring(7);
    const jwtSecret = process.env.JWT_SECRET;
    
    if (!jwtSecret) {
      next();
      return;
    }

    try {
      const decoded = jwt.verify(token, jwtSecret) as JwtPayload;
      req.user = {
        id: decoded.id,
        userId: decoded.id, // For backward compatibility
        email: decoded.email,
        iat: decoded.iat,
        exp: decoded.exp
      };
    } catch (jwtError) {
      // Invalid token, but continue without user info
      console.warn('Optional auth failed:', jwtError);
    }
    
    next();
  } catch (error) {
    console.error('Optional auth middleware error:', error);
    next(); // Continue even if there's an error
  }
};
