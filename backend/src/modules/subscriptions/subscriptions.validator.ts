import { z } from 'zod';

export const redeemCouponSchema = z.object({
  code: z.string().min(1).max(64).toUpperCase(),
});

export const checkoutSchema = z.object({
  // No body required for now – plan is always MONTHLY
});

export type RedeemCouponInput = z.infer<typeof redeemCouponSchema>;
