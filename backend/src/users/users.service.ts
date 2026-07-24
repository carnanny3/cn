import { BadRequestException, ConflictException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
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
