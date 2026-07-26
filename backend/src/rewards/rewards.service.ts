import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { generateReferralCode } from '../common/crypto.util';

// PRD doesn't specify a points-earning formula or referral reward amount
// (§22.10 covers only the data model) — these are reasonable starting
// values, easy to retune once real usage data exists.
const POINTS_PER_AED_SPENT = 0.1; // 1 point per AED 10 spent on a completed booking
const REFERRAL_BONUS_POINTS = 50;

@Injectable()
export class RewardsService {
  constructor(private readonly prisma: PrismaService) {}

  private async getOrCreateAccount(userId: string) {
    return this.prisma.rewardsAccount.upsert({
      where: { userId },
      create: { userId },
      update: {},
    });
  }

  /** Generates and persists a referral code for this user on first use — registration doesn't block on it, so older accounts get one lazily. */
  async ensureReferralCode(userId: string): Promise<string> {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: userId }, select: { referralCode: true } });
    if (user.referralCode) return user.referralCode;

    // Extremely low collision odds (33^7) — retry once on the rare unique-constraint clash.
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const code = generateReferralCode();
        const updated = await this.prisma.user.update({ where: { id: userId }, data: { referralCode: code } });
        return updated.referralCode!;
      } catch {
        continue;
      }
    }
    throw new Error('Could not generate a unique referral code — please try again.');
  }

  async getMyRewards(userId: string) {
    const account = await this.getOrCreateAccount(userId);
    const [transactions, referralCode, referrals] = await Promise.all([
      this.prisma.rewardsTransaction.findMany({
        where: { rewardsAccountId: account.id },
        orderBy: { createdAt: 'desc' },
        take: 50,
      }),
      this.ensureReferralCode(userId),
      this.prisma.referral.findMany({
        where: { referrerId: userId },
        orderBy: { createdAt: 'desc' },
        include: { referredUser: { select: { fullName: true } } },
      }),
    ]);

    return { pointsBalance: account.pointsBalance, transactions, referralCode, referrals };
  }

  async awardPoints(userId: string, points: number, reason: string, relatedEntityId?: string) {
    if (points <= 0) return;
    const account = await this.getOrCreateAccount(userId);
    await this.prisma.$transaction([
      this.prisma.rewardsTransaction.create({
        data: { rewardsAccountId: account.id, points, reason: reason as never, relatedEntityId },
      }),
      this.prisma.rewardsAccount.update({
        where: { id: account.id },
        data: { pointsBalance: { increment: points } },
      }),
    ]);
  }

  /** Called at registration when a new user signs up with someone else's referral code. */
  async redeemReferralCode(newUserId: string, code: string) {
    const referrer = await this.prisma.user.findUnique({ where: { referralCode: code } });
    if (!referrer || referrer.id === newUserId) return; // silently ignore invalid/self-referral codes — not worth failing signup over

    await this.prisma.referral.create({
      data: { referrerId: referrer.id, referredUserId: newUserId, status: 'pending' },
    });
  }

  /** Called when a booking completes — awards spend-based points, and if this is the customer's first completed booking, finalizes any pending referral that brought them in. */
  async onBookingCompleted(customerId: string, totalAmount: number) {
    const earnedPoints = Math.round(totalAmount * POINTS_PER_AED_SPENT);
    await this.awardPoints(customerId, earnedPoints, 'booking_completed');

    const referral = await this.prisma.referral.findUnique({ where: { referredUserId: customerId } });
    if (referral && referral.status === 'pending') {
      await this.prisma.referral.update({
        where: { id: referral.id },
        data: { status: 'completed', rewardIssued: true },
      });
      await this.awardPoints(referral.referrerId, REFERRAL_BONUS_POINTS, 'referral_bonus', referral.id);
    }
  }
}
