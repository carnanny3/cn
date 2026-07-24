import { Test } from '@nestjs/testing';
import { ConflictException, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import { PrismaService } from '../prisma/prisma.service';
import { hashPassword, hashValue } from '../common/crypto.util';

describe('AuthService', () => {
  let service: AuthService;
  let prisma: {
    user: Record<string, jest.Mock>;
    otpCode: Record<string, jest.Mock>;
    refreshToken: Record<string, jest.Mock>;
  };

  beforeEach(async () => {
    prisma = {
      user: {
        findUnique: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        findUniqueOrThrow: jest.fn(),
      },
      otpCode: {
        create: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      refreshToken: {
        create: jest.fn(),
        findFirst: jest.fn(),
        update: jest.fn(),
        updateMany: jest.fn(),
      },
    };

    const moduleRef = await Test.createTestingModule({
      providers: [AuthService, { provide: PrismaService, useValue: prisma }, JwtService],
    }).compile();

    service = moduleRef.get(AuthService);
  });

  describe('register', () => {
    it('rejects registering an email that already exists', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'existing-user' });

      await expect(
        service.register({ email: 'rashid@example.com', password: 'password123', fullName: 'Rashid' }),
      ).rejects.toThrow(ConflictException);
    });

    it('creates an active user with a hashed password and issues tokens', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      prisma.user.create.mockResolvedValue({
        id: 'new-user',
        email: 'new@example.com',
        role: 'customer',
      });
      prisma.refreshToken.create.mockResolvedValue({});

      const result = await service.register({
        email: 'new@example.com',
        password: 'password123',
        fullName: 'New User',
      });

      expect(prisma.user.create).toHaveBeenCalled();
      const createArgs = prisma.user.create.mock.calls[0][0];
      expect(createArgs.data.passwordHash).not.toBe('password123');
      expect(createArgs.data.status).toBe('active');
      expect(result.accessToken).toBeDefined();
      expect(result.refreshToken).toBeDefined();
    });
  });

  describe('login', () => {
    it('rejects an unregistered email', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      await expect(
        service.login({ email: 'nobody@example.com', password: 'password123' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects an incorrect password', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        passwordHash: hashPassword('correct-password'),
        status: 'active',
      });
      await expect(
        service.login({ email: 'rashid@example.com', password: 'wrong-password' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects a suspended account even with the correct password', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        passwordHash: hashPassword('correct-password'),
        status: 'suspended',
      });
      await expect(
        service.login({ email: 'rashid@example.com', password: 'correct-password' }),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('issues tokens for a correct password on an active account', async () => {
      prisma.user.findUnique.mockResolvedValue({
        id: 'user-1',
        email: 'rashid@example.com',
        role: 'customer',
        passwordHash: hashPassword('correct-password'),
        status: 'active',
      });
      prisma.refreshToken.create.mockResolvedValue({});

      const result = await service.login({ email: 'rashid@example.com', password: 'correct-password' });

      expect(result.accessToken).toBeDefined();
      expect(result.tokenType).toBe('Bearer');
    });
  });

  describe('forgotPassword', () => {
    it('does not reveal whether the email is registered', async () => {
      prisma.user.findUnique.mockResolvedValue(null);
      const result = await service.forgotPassword({ email: 'nobody@example.com' });
      expect(result.message).toMatch(/if that email is registered/i);
      expect(prisma.otpCode.create).not.toHaveBeenCalled();
    });

    it('issues a reset code for a registered email', async () => {
      prisma.user.findUnique.mockResolvedValue({ id: 'user-1', email: 'rashid@example.com' });
      prisma.otpCode.create.mockResolvedValue({});
      const result = await service.forgotPassword({ email: 'rashid@example.com' });
      expect(prisma.otpCode.create).toHaveBeenCalled();
      expect(result.devCode).toMatch(/^\d{6}$/);
    });
  });

  describe('resetPassword', () => {
    it('rejects an incorrect code', async () => {
      prisma.otpCode.findFirst.mockResolvedValue({
        id: 'code-1',
        codeHash: hashValue('111111'),
        expiresAt: new Date(Date.now() + 60_000),
        attempts: 0,
      });
      await expect(
        service.resetPassword({ email: 'rashid@example.com', code: '222222', newPassword: 'newpassword123' }),
      ).rejects.toThrow(BadRequestException);
    });

    it('updates the password on a correct, unexpired code', async () => {
      prisma.otpCode.findFirst.mockResolvedValue({
        id: 'code-1',
        codeHash: hashValue('123456'),
        expiresAt: new Date(Date.now() + 60_000),
        attempts: 0,
      });
      prisma.otpCode.update.mockResolvedValue({});
      prisma.user.update.mockResolvedValue({});

      const result = await service.resetPassword({
        email: 'rashid@example.com',
        code: '123456',
        newPassword: 'newpassword123',
      });

      expect(prisma.user.update).toHaveBeenCalled();
      expect(result.message).toMatch(/reset successfully/i);
    });
  });

  describe('refresh', () => {
    it('rejects an unknown or revoked refresh token', async () => {
      prisma.refreshToken.findFirst.mockResolvedValue(null);
      await expect(service.refresh('bogus-token')).rejects.toThrow();
    });
  });
});
