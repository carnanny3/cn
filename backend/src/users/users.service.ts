import { BadRequestException, ConflictException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { randomBytes } from 'crypto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { DeleteAccountDto } from './dto/delete-account.dto';
import { hashPassword, verifyPassword } from '../common/crypto.util';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async findById(id: string) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found.' });
    return this.toProfile(user);
  }

  async update(id: string, dto: UpdateUserDto) {
    if (dto.email) {
      const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
      if (existing && existing.id !== id) {
        throw new ConflictException({ code: 'EMAIL_ALREADY_IN_USE', message: 'That email is already in use by another account.' });
      }
    }
    if (dto.phoneNumber) {
      const existing = await this.prisma.user.findUnique({ where: { phoneNumber: dto.phoneNumber } });
      if (existing && existing.id !== id) {
        throw new ConflictException({ code: 'PHONE_ALREADY_IN_USE', message: 'That phone number is already in use by another account.' });
      }
    }
    const user = await this.prisma.user.update({ where: { id }, data: dto });
    return this.toProfile(user);
  }

  async changePassword(id: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id } });
    if (!verifyPassword(dto.currentPassword, user.passwordHash)) {
      throw new UnauthorizedException({ code: 'INCORRECT_PASSWORD', message: 'Current password is incorrect.' });
    }
    if (dto.newPassword === dto.currentPassword) {
      throw new BadRequestException({ code: 'SAME_PASSWORD', message: 'New password must be different from the current password.' });
    }
    await this.prisma.user.update({ where: { id }, data: { passwordHash: hashPassword(dto.newPassword) } });
    return { message: 'Password updated successfully.' };
  }

  /**
   * Erases the customer's personal data while leaving financial records intact,
   * which is what Play requires of an account-deletion path and what tax
   * retention rules require of the books.
   *
   * The User row itself is kept and blanked rather than deleted: bookings,
   * payments and invoices all carry a non-nullable customerId, so removing the
   * row would either cascade into those records or fail outright. Keeping it
   * anonymised leaves every foreign key valid while the person behind it
   * becomes unidentifiable.
   *
   * Known limitation: JwtAuthGuard verifies tokens without a database lookup,
   * so an access token issued before deletion keeps working until it expires
   * (ACCESS_TOKEN_TTL, 15 minutes). Refresh tokens are deleted here, so the
   * window cannot be extended. Closing it entirely would mean a per-request
   * user lookup on every authenticated endpoint — a cost paid on every call to
   * revoke slightly faster on a rare one.
   */
  async deleteAccount(id: string, dto: DeleteAccountDto) {
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found.' });
    if (!verifyPassword(dto.password, user.passwordHash)) {
      throw new UnauthorizedException({ code: 'INCORRECT_PASSWORD', message: 'Password is incorrect.' });
    }

    await this.prisma.$transaction(async (tx) => {
      // Free-text the customer wrote, and anything that could re-identify them.
      const conversations = await tx.aiConversation.findMany({ where: { userId: id }, select: { id: true } });
      const conversationIds = conversations.map((c) => c.id);
      if (conversationIds.length > 0) {
        await tx.aiMessage.deleteMany({ where: { conversationId: { in: conversationIds } } });
        await tx.aiConversation.deleteMany({ where: { id: { in: conversationIds } } });
      }

      const tickets = await tx.supportTicket.findMany({ where: { userId: id }, select: { id: true } });
      const ticketIds = tickets.map((t) => t.id);
      if (ticketIds.length > 0) {
        await tx.supportTicketMessage.deleteMany({ where: { ticketId: { in: ticketIds } } });
        await tx.supportTicket.deleteMany({ where: { id: { in: ticketIds } } });
      }

      const rewardsAccount = await tx.rewardsAccount.findUnique({ where: { userId: id }, select: { id: true } });
      if (rewardsAccount) {
        await tx.rewardsTransaction.deleteMany({ where: { rewardsAccountId: rewardsAccount.id } });
        await tx.rewardsAccount.delete({ where: { id: rewardsAccount.id } });
      }

      await tx.referral.deleteMany({ where: { OR: [{ referrerId: id }, { referredUserId: id }] } });
      await tx.notification.deleteMany({ where: { userId: id } });
      await tx.notificationPreference.deleteMany({ where: { userId: id } });
      await tx.deviceToken.deleteMany({ where: { userId: id } });
      await tx.refreshToken.deleteMany({ where: { userId: id } });
      await tx.otpCode.deleteMany({ where: { userId: id } });

      // Photographed registration and insurance papers carry the owner's
      // identity, so they go — but only for vehicles nobody else still owns.
      const owned = await tx.vehicleOwner.findMany({ where: { userId: id }, select: { vehicleId: true } });
      for (const { vehicleId } of owned) {
        const otherOwners = await tx.vehicleOwner.count({ where: { vehicleId, userId: { not: id } } });
        if (otherOwners === 0) {
          await tx.vehicleDocument.deleteMany({ where: { vehicleId } });
        }
      }
      // The vehicles themselves stay: bookings and inspections reference them.
      await tx.vehicleOwner.deleteMany({ where: { userId: id } });

      // Keep the score so partner ratings stay meaningful, drop their words.
      await tx.review.updateMany({ where: { reviewerId: id }, data: { comment: null } });

      await tx.user.update({
        where: { id },
        data: {
          // Unique columns need placeholder values rather than nulls.
          email: `deleted-${id}@deleted.invalid`,
          phoneNumber: null,
          referralCode: null,
          fullName: 'Deleted user',
          profilePhotoUrl: null,
          emirate: null,
          // Unguessable hash plus the suspended check in AuthService.login
          // means this account cannot be signed into again.
          passwordHash: hashPassword(randomBytes(32).toString('hex')),
          status: 'suspended',
        },
      });
    });

    return { message: 'Your account and personal data have been deleted.' };
  }

  async profileCompletion(id: string): Promise<number> {
    const user = await this.prisma.user.findUniqueOrThrow({ where: { id } });
    const fields = [user.fullName, user.phoneNumber, user.emirate, user.profilePhotoUrl];
    const filled = fields.filter(Boolean).length;
    return Math.round((filled / fields.length) * 100);
  }

  private toProfile(user: {
    id: string;
    phoneNumber: string | null;
    email: string;
    fullName: string;
    preferredLanguage: string;
    emirate: string | null;
    status: string;
    accountType: string;
    role: string;
    profilePhotoUrl: string | null;
    createdAt: Date;
  }) {
    return {
      id: user.id,
      phoneNumber: user.phoneNumber,
      email: user.email,
      fullName: user.fullName,
      preferredLanguage: user.preferredLanguage,
      emirate: user.emirate,
      status: user.status,
      accountType: user.accountType,
      role: user.role,
      profilePhotoUrl: user.profilePhotoUrl,
      createdAt: user.createdAt,
    };
  }
}
