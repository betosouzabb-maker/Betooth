import { z } from 'zod';

const phoneRegex = /^\+?[1-9]\d{9,14}$/;

const normalizePhone = (value: string): string => value.replace(/[^\d+]/g, '');

const requiredBirthDateSchema = z
  .string()
  .trim()
  .refine((value) => !Number.isNaN(Date.parse(value)), 'birthDate must be a valid date')
  .transform((value) => new Date(value));

const optionalBirthDateSchema = z
  .string()
  .trim()
  .refine((value) => !Number.isNaN(Date.parse(value)), 'birthDate must be a valid date')
  .transform((value) => new Date(value))
  .optional();

const requiredPhoneSchema = z
  .string()
  .trim()
  .transform(normalizePhone)
  .refine((value) => phoneRegex.test(value), 'phone must be a valid phone number');

const optionalPhoneSchema = z
  .string()
  .trim()
  .transform(normalizePhone)
  .refine((value) => phoneRegex.test(value), 'phone must be a valid phone number')
  .optional();

const devicePlatformSchema = z.enum(['ANDROID', 'IOS', 'WEB', 'DESKTOP', 'UNKNOWN']).optional();

export const loginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string().min(8)
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const registerSchema = z.object({
  body: z.object({
    name: z.string().trim().min(2).max(80),
    email: z.string().email(),
    birthDate: requiredBirthDateSchema,
    phone: requiredPhoneSchema,
    password: z.string().min(8),
    deviceId: z.string().trim().min(3).max(191).optional(),
    deviceName: z.string().trim().min(1).max(120).optional(),
    devicePlatform: devicePlatformSchema,
    appVersion: z.string().trim().min(1).max(50).optional(),
    osVersion: z.string().trim().min(1).max(50).optional(),
    pushToken: z.string().trim().min(1).max(255).optional()
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const refreshSchema = z.object({
  body: z.object({
    refreshToken: z.string().min(1)
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const logoutSchema = refreshSchema;

export const forgotPasswordSchema = z.object({
  body: z.object({
    email: z.string().email()
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const resetPasswordSchema = z.object({
  body: z.object({
    token: z.string().min(1),
    password: z.string().min(8)
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateMeSchema = z.object({
  body: z
    .object({
      name: z.string().trim().min(2).max(80).optional(),
      phone: optionalPhoneSchema,
      birthDate: optionalBirthDateSchema,
      profilePhotoUrl: z.string().trim().url().optional()
    })
    .refine((value) => Object.values(value).some((item) => item !== undefined), {
      message: 'At least one field must be provided'
    }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});