import rateLimit from 'express-rate-limit';
import { Request, Response, NextFunction } from 'express';

// Allow disabling rate limiting for testing via environment variable
const DISABLE_RATE_LIMIT = process.env.DISABLE_RATE_LIMIT === 'true';

// Create rate limiter instances
const globalRateLimiterInstance = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: parseInt(process.env.RATE_LIMIT_MAX || '500', 10), // Configurable max requests per IP per window
  message: { error: 'Rate limit exceeded. Try again in 1 minute.' },
  standardHeaders: true, // Return rate limit info in `X-RateLimit-*` headers
  legacyHeaders: false, // Disable `X-RateLimit-*` headers
  handler: (_req: Request, res: Response) => {
    res.status(429).json({ error: 'Rate limit exceeded. Try again in 1 minute.' });
  },
});

const orderRateLimiterInstance = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: parseInt(process.env.ORDER_RATE_LIMIT_MAX || '10', 10), // Configurable max orders per IP per window
  message: { error: 'Too many orders placed. Please wait.' },
  standardHeaders: true,
  legacyHeaders: false,
  handler: (_req: Request, res: Response) => {
    res.status(429).json({ error: 'Too many orders placed. Please wait.' });
  },
});

// Conditional rate limiter middleware - bypass if DISABLE_RATE_LIMIT is set
export const globalRateLimiter = (req: Request, res: Response, next: NextFunction) => {
  if (DISABLE_RATE_LIMIT) {
    return next();
  }
  return globalRateLimiterInstance(req, res, next);
};

export const orderRateLimiter = (req: Request, res: Response, next: NextFunction) => {
  if (DISABLE_RATE_LIMIT) {
    return next();
  }
  return orderRateLimiterInstance(req, res, next);
};
