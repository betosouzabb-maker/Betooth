import { authGuard } from '../../common/middleware/auth-guard';

export const requireAuth = authGuard;