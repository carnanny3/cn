import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
import { RewardsService } from '../rewards/rewards.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import {
  generateOpaqueToken,
  generateOtp,
  hashPassword,
  hashValue,
  verifyPassword,
} from '../common/crypto.util';

const RESET_CODE_TTL_MINUTES = 15;
const RESET_CODE_MAX_ATTEMPTS = 5;
const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL_DAYS = 30;

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly rewardsService: RewardsService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (existing) {
      throw new ConflictException({
        code: 'EMAIL_ALREADY_REGISTERED',
        message: 'An account with this email already exists. Try logging in instead.',
      });
    }

    if (dto.phoneNumber) {
      const phoneTaken = await this.prisma.user.findUnique({ where: { phoneNumber: dto.phoneNumber } });
      if (phoneTaken) {
        throw new ConflictException({
          code: 'PHONE_ALREADY_REGISTERED',
          message: 'An account with this phone number already exists.',
        });
      }
    }

    const user = await this.prisma.user.create({
      data: {
        email: dto.email,
        phoneNumber: dto.phoneNumber,
        fullName: dto.fullName,
        passwordHash: hashPassword(dto.password),
        status: 'active',
      },
    });

    if (dto.referralCode) {
      await this.rewardsService.redeemReferralCode(user.id, dto.referralCode);
    }

    return this.issueTokens(user.id, user.role, user.email);
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    if (!user || !verifyPassword(dto.password, user.passwordHash)) {
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Incorrect email or password.',
      });
    }
    if (user.status === 'suspended') {
      throw new UnauthorizedException({
        code: 'ACCOUNT_SUSPENDED',
        message: 'This account has been suspended. Contact support for help.',
      });
    }
    return this.issueTokens(user.id, user.role, user.email);
  }

  /**
   * Dev-mode code delivery: logged to console and returned in the response
   * instead of sent via a real email provider — wire a transactional email
   * service here before production use.
   */
  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email } });
    // Always respond success-shaped, whether or not the email exists, so this
    // endpoint can't be used to enumerate registered accounts.
    if (!user) {
      return { message: 'If that email is registered, a reset code has been sent.' };
    }

    const code = generateOtp(6);
    await this.prisma.otpCode.create({
      data: {
        userId: user.id,
        identifier: dto.email,
        codeHash: hashValue(code),
        purpose: 'password_reset',
        expiresAt: new Date(Date.now() + RESET_CODE_TTL_MINUTES * 60 * 1000),
      },
    });

    // eslint-disable-next-line no-console
    console.log(`[DEV RESET CODE] ${dto.email}: ${code} (expires in ${RESET_CODE_TTL_MINUTES}m)`);

    const devCode = process.env.NODE_ENV === 'production' ? undefined : code;
    return { message: 'If that email is registered, a reset code has been sent.', devCode };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const record = await this.prisma.otpCode.findFirst({
      where: { identifier: dto.email, purpose: 'password_reset', consumed: false },
      orderBy: { createdAt: 'desc' },
    });

    if (!record) {
      throw new BadRequestException({
        code: 'RESET_CODE_NOT_FOUND',
        message: 'No pending reset request found for this email. Request a new code.',
      });
    }
    if (record.expiresAt < new Date()) {
      throw new BadRequestException({
        code: 'RESET_CODE_EXPIRED',
        message: 'This code has expired. Please request a new one.',
      });
    }
    if (record.attempts >= RESET_CODE_MAX_ATTEMPTS) {
      throw new BadRequestException({
        code: 'RESET_CODE_LOCKED',
        message: 'Too many incorrect attempts. Please request a new code.',
      });
    }
    if (hashValue(dto.code) !== record.codeHash) {
      await this.prisma.otpCode.update({ where: { id: record.id }, data: { attempts: { increment: 1 } } });
      throw new BadRequestException({
        code: 'RESET_CODE_INCORRECT',
        message: 'Incorrect code. Please try again.',
      });
    }

    await this.prisma.otpCode.update({ where: { id: record.id }, data: { consumed: true } });
    await this.prisma.user.update({
      where: { email: dto.email },
      data: { passwordHash: hashPassword(dto.newPassword) },
    });

    return { message: 'Password reset successfully. You can now log in with your new password.' };
  }

  async refresh(refreshToken: string) {
    const tokenHash = hashValue(refreshToken);
    const record = await this.prisma.refreshToken.findFirst({
      where: { tokenHash, revoked: false },
    });

    if (!record || record.expiresAt < new Date()) {
      throw new UnauthorizedException({
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Refresh token is invalid or expired. Please log in again.',
      });
    }

    await this.prisma.refreshToken.update({ where: { id: record.id }, data: { revoked: true } });

    const user = await this.prisma.user.findUniqueOrThrow({ where: { id: record.userId } });
    return this.issueTokens(user.id, user.role, user.email);
  }

  async logout(refreshToken: string) {
    const tokenHash = hashValue(refreshToken);
    await this.prisma.refreshToken.updateMany({ where: { tokenHash }, data: { revoked: true } });
    return { success: true };
  }

  async issueTokensForUser(userId: string, role: string, email: string) {
    return this.issueTokens(userId, role, email);
  }

  private async issueTokens(userId: string, role: string, email: string) {
    const payload = { sub: userId, role, email };
    const accessToken = this.jwtService.sign(payload, {
      secret: process.env.JWT_ACCESS_SECRET || 'dev-access-secret',
      expiresIn: ACCESS_TOKEN_TTL,
    });

    const refreshToken = generateOpaqueToken();
    await this.prisma.refreshToken.create({
      data: {
        userId,
        tokenHash: hashValue(refreshToken),
        expiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_DAYS * 24 * 60 * 60 * 1000),
      },
    });

    return { accessToken, refreshToken, expiresIn: 15 * 60, tokenType: 'Bearer' };
  }
}
