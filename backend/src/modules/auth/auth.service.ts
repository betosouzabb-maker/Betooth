import { DevicePlatform, SessionStatus, User, UserStatus } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { createHash, randomBytes, randomUUID } from 'node:crypto';
import jwt, { JwtPayload, SignOptions } from 'jsonwebtoken';
import { prisma } from '../../infra/database/prisma';
import { AppError } from '../../common/middleware/error-handler';
import { env } from '../../config/env';
import { logger } from '../../common/utils/logger';

type LoginInput = {
  email: string;
  password: string;
};

type RegisterInput = {
  name: string;
  email: string;
  birthDate: Date;
  phone: string;
  password: string;
  deviceId?: string;
  deviceName?: string;
  devicePlatform?: DevicePlatform;
  appVersion?: string;
  osVersion?: string;
  pushToken?: string;
};

type RefreshInput = {
  refreshToken: string;
};

type LogoutInput = {
  refreshToken: string;
};

type ForgotPasswordInput = {
  email: string;
};

type ResetPasswordInput = {
  token: string;
  password: string;
};

type UpdateMeInput = {
  name?: string;
  phone?: string;
  birthDate?: Date;
  profilePhotoUrl?: string;
};

type RequestContext = {
  ipAddress?: string;
  userAgent?: string | null;
};

type TokenPayload = {
  id: string;
  userId: string;
  email: string;
  role: string;
  sessionId?: string;
  type: 'access' | 'refresh';
};

const accessTokenOptions: SignOptions = {
  expiresIn: env.JWT_ACCESS_EXPIRES_IN as SignOptions['expiresIn']
};

const refreshTokenOptions: SignOptions = {
  expiresIn: env.JWT_REFRESH_EXPIRES_IN as SignOptions['expiresIn']
};

const blockedStatuses = new Set<UserStatus>([UserStatus.SUSPENDED, UserStatus.DELETED]);

const hashValue = (value: string): string => createHash('sha256').update(value).digest('hex');

const parseDurationToMs = (value: string): number => {
  const parsed = /^(\d+)([smhd])$/.exec(value.trim());

  if (!parsed) {
    throw new Error(`Unsupported duration format: ${value}`);
  }

  const amount = Number(parsed[1]);
  const unit = parsed[2] as 's' | 'm' | 'h' | 'd';
  const unitMap: Record<'s' | 'm' | 'h' | 'd', number> = {
    s: 1000,
    m: 60_000,
    h: 3_600_000,
    d: 86_400_000
  };

  return amount * unitMap[unit];
};

const refreshTokenTtlMs = parseDurationToMs(env.JWT_REFRESH_EXPIRES_IN);
const resetPasswordTtlMs = 3_600_000;

const mapUserProfile = (user: Pick<User, 'id' | 'displayName' | 'email' | 'birthDate' | 'phone' | 'avatarUrl' | 'role'>) => ({
  id: user.id,
  name: user.displayName,
  email: user.email,
  birthDate: user.birthDate?.toISOString() ?? null,
  phone: user.phone ?? null,
  profilePhotoUrl: user.avatarUrl ?? null,
  role: user.role
});

const ensureUserIsNotBlocked = (user: Pick<User, 'status'>): void => {
  if (blockedStatuses.has(user.status)) {
    throw new AppError('User account is blocked', 403, 'AUTH_USER_BLOCKED');
  }
};

const signAccessToken = (user: Pick<User, 'id' | 'email' | 'role'>, sessionId: string): string =>
  jwt.sign(
    {
      id: user.id,
      userId: user.id,
      email: user.email,
      role: user.role,
      sessionId,
      type: 'access'
    } satisfies TokenPayload,
    env.JWT_ACCESS_SECRET,
    accessTokenOptions
  );

const signRefreshToken = (user: Pick<User, 'id' | 'email' | 'role'>, sessionId: string): string =>
  jwt.sign(
    {
      id: user.id,
      userId: user.id,
      email: user.email,
      role: user.role,
      sessionId,
      type: 'refresh'
    } satisfies TokenPayload,
    env.JWT_REFRESH_SECRET,
    refreshTokenOptions
  );

const createSessionTokens = async (
  user: Pick<User, 'id' | 'email' | 'role'>,
  context: RequestContext
) => {
  const sessionId = randomUUID();
  const refreshToken = signRefreshToken(user, sessionId);
  const accessToken = signAccessToken(user, sessionId);

  await prisma.userSession.create({
    data: {
      id: sessionId,
      userId: user.id,
      refreshToken: hashValue(refreshToken),
      expiresAt: new Date(Date.now() + refreshTokenTtlMs),
      ipAddress: context.ipAddress,
      userAgent: context.userAgent ?? undefined,
      status: SessionStatus.ACTIVE
    }
  });

  return {
    accessToken,
    refreshToken
  };
};

const verifyRefreshTokenPayload = (refreshToken: string): (JwtPayload & TokenPayload) => {
  try {
    const payload = jwt.verify(refreshToken, env.JWT_REFRESH_SECRET) as JwtPayload & TokenPayload;

    if (payload.type !== 'refresh' || !payload.sessionId || !payload.userId) {
      throw new AppError('Refresh token is invalid', 401, 'AUTH_REFRESH_INVALID');
    }

    return payload;
  } catch (error) {
    throw new AppError('Refresh token is invalid', 401, 'AUTH_REFRESH_INVALID', error);
  }
};

export const authService = {
  async login(input: LoginInput, context: RequestContext) {
    const user = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase().trim() }
    });

    if (!user) {
      throw new AppError('Invalid email or password', 401, 'AUTH_INVALID_CREDENTIALS');
    }

    ensureUserIsNotBlocked(user);

    const isPasswordValid = await bcrypt.compare(input.password, user.passwordHash);

    if (!isPasswordValid) {
      throw new AppError('Invalid email or password', 401, 'AUTH_INVALID_CREDENTIALS');
    }

    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() }
    });

    const session = await createSessionTokens(user, context);

    return {
      user: mapUserProfile(user),
      ...session
    };
  },
  async register(input: RegisterInput, context: RequestContext) {
    const email = input.email.toLowerCase().trim();
    const existingUser = await prisma.user.findUnique({
      where: { email }
    });

    if (existingUser) {
      throw new AppError('Email is already in use', 409, 'AUTH_EMAIL_IN_USE');
    }

    const passwordHash = await bcrypt.hash(input.password, 12);

    const user = await prisma.user.create({
      data: {
        email,
        displayName: input.name.trim(),
        passwordHash,
        birthDate: input.birthDate,
        phone: input.phone,
        status: UserStatus.ACTIVE
      }
    });

    if (input.deviceId) {
      await prisma.device.upsert({
        where: { deviceIdentifier: input.deviceId },
        update: {
          userId: user.id,
          name: input.deviceName,
          platform: input.devicePlatform ?? DevicePlatform.UNKNOWN,
          appVersion: input.appVersion,
          osVersion: input.osVersion,
          pushToken: input.pushToken,
          lastSeenAt: new Date()
        },
        create: {
          userId: user.id,
          deviceIdentifier: input.deviceId,
          name: input.deviceName,
          platform: input.devicePlatform ?? DevicePlatform.UNKNOWN,
          appVersion: input.appVersion,
          osVersion: input.osVersion,
          pushToken: input.pushToken,
          lastSeenAt: new Date()
        }
      });
    }

    const session = await createSessionTokens(user, context);

    return {
      user: mapUserProfile(user),
      ...session
    };
  },
  async refresh(input: RefreshInput, context: RequestContext) {
    const payload = verifyRefreshTokenPayload(input.refreshToken);
    const session = await prisma.userSession.findUnique({
      where: { id: payload.sessionId },
      include: { user: true }
    });

    if (!session || session.status !== SessionStatus.ACTIVE || session.revokedAt || session.expiresAt <= new Date()) {
      throw new AppError('Refresh token is invalid', 401, 'AUTH_REFRESH_INVALID');
    }

    if (session.refreshToken !== hashValue(input.refreshToken)) {
      await prisma.userSession.update({
        where: { id: session.id },
        data: {
          status: SessionStatus.REVOKED,
          revokedAt: new Date()
        }
      });

      throw new AppError('Refresh token is invalid', 401, 'AUTH_REFRESH_INVALID');
    }

    ensureUserIsNotBlocked(session.user);

    await prisma.userSession.update({
      where: { id: session.id },
      data: {
        status: SessionStatus.REVOKED,
        revokedAt: new Date()
      }
    });

    return createSessionTokens(session.user, context);
  },
  async logout(input: LogoutInput) {
    try {
      const payload = verifyRefreshTokenPayload(input.refreshToken);
      const session = await prisma.userSession.findUnique({
        where: { id: payload.sessionId }
      });

      if (session && session.refreshToken === hashValue(input.refreshToken) && !session.revokedAt) {
        await prisma.userSession.update({
          where: { id: session.id },
          data: {
            status: SessionStatus.REVOKED,
            revokedAt: new Date()
          }
        });
      }
    } catch (error) {
      logger.warn({ error }, 'Logout attempted with invalid refresh token');
    }

    return {
      loggedOut: true
    };
  },
  async forgotPassword(input: ForgotPasswordInput) {
    const user = await prisma.user.findUnique({
      where: { email: input.email.toLowerCase().trim() }
    });

    if (!user) {
      return {
        message: 'If this email exists, a reset link has been sent.'
      };
    }

    const rawToken = randomBytes(32).toString('hex');
    const hashedToken = hashValue(rawToken);

    await prisma.passwordResetToken.create({
      data: {
        userId: user.id,
        token: hashedToken,
        expiresAt: new Date(Date.now() + resetPasswordTtlMs)
      }
    });

    console.info(`[Betooth] Password reset token for ${user.email}: ${rawToken}`);

    return {
      message: 'If this email exists, a reset link has been sent.'
    };
  },
  async resetPassword(input: ResetPasswordInput) {
    const hashedToken = hashValue(input.token);
    const resetToken = await prisma.passwordResetToken.findUnique({
      where: { token: hashedToken },
      include: { user: true }
    });

    if (!resetToken || resetToken.usedAt || resetToken.expiresAt <= new Date()) {
      throw new AppError('Reset token is invalid or expired', 400, 'AUTH_RESET_TOKEN_INVALID');
    }

    const passwordHash = await bcrypt.hash(input.password, 12);

    await prisma.$transaction([
      prisma.user.update({
        where: { id: resetToken.userId },
        data: { passwordHash }
      }),
      prisma.passwordResetToken.update({
        where: { id: resetToken.id },
        data: { usedAt: new Date() }
      }),
      prisma.userSession.updateMany({
        where: {
          userId: resetToken.userId,
          status: SessionStatus.ACTIVE,
          revokedAt: null
        },
        data: {
          status: SessionStatus.REVOKED,
          revokedAt: new Date()
        }
      })
    ]);

    return {
      message: 'Password updated successfully.'
    };
  },
  async me(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user || user.deletedAt) {
      throw new AppError('User not found', 404, 'AUTH_USER_NOT_FOUND');
    }

    ensureUserIsNotBlocked(user);

    return mapUserProfile(user);
  },
  async updateMe(userId: string, input: UpdateMeInput) {
    const existingUser = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!existingUser || existingUser.deletedAt) {
      throw new AppError('User not found', 404, 'AUTH_USER_NOT_FOUND');
    }

    ensureUserIsNotBlocked(existingUser);

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        displayName: input.name,
        phone: input.phone,
        birthDate: input.birthDate,
        avatarUrl: input.profilePhotoUrl
      }
    });

    return mapUserProfile(user);
  }
};