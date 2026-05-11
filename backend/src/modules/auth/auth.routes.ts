import { Router } from 'express';
import { validate } from '../../common/middleware/validator';
import { authRateLimiter } from '../../common/middleware/rate-limiter';
import { authController } from './auth.controller';
import { requireAuth } from './auth.middleware';
import {
  forgotPasswordSchema,
  loginSchema,
  logoutSchema,
  refreshSchema,
  registerSchema,
  resetPasswordSchema,
  updateMeSchema
} from './auth.validator';

export const authRoutes = Router();

authRoutes.post('/login', authRateLimiter, validate(loginSchema), authController.login);
authRoutes.post('/register', authRateLimiter, validate(registerSchema), authController.register);
authRoutes.post('/refresh', validate(refreshSchema), authController.refresh);
authRoutes.post('/logout', validate(logoutSchema), authController.logout);
authRoutes.post('/forgot-password', validate(forgotPasswordSchema), authController.forgotPassword);
authRoutes.post('/reset-password', validate(resetPasswordSchema), authController.resetPassword);
authRoutes.get('/me', requireAuth, authController.me);
authRoutes.patch('/me', requireAuth, validate(updateMeSchema), authController.updateMe);