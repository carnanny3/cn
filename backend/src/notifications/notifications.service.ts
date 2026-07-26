import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { sendPush } from './providers/push.provider';
import { sendSms } from './providers/sms.provider';
import { sendWhatsApp } from './providers/whatsapp.provider';
import { sendEmail } from './providers/email.provider';

interface NotifyInput {
  userId: string;
  category: string;
  title: string;
  body: string;
  relatedEntityType?: string;
  relatedEntityId?: string;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Fans out to every enabled channel for this user/category (default: push
   * only, per notification_preferences). Each channel dispatches to a real
   * provider (FCM/Twilio/SMTP) when configured, falling back to a log line
   * otherwise — see providers/*.ts.
   */
  async notify(input: NotifyInput) {
    const prefs = await this.prisma.notificationPreference.findMany({
      where: { userId: input.userId, category: input.category },
    });

    const channels = prefs.length > 0
      ? prefs.filter((p) => p.enabled).map((p) => p.channel)
      : (['push'] as const);

    const created = await Promise.all(
      channels.map((channel) =>
        this.prisma.notification.create({
          data: {
            userId: input.userId,
            category: input.category,
            channel,
            title: input.title,
            body: input.body,
            relatedEntityType: input.relatedEntityType,
            relatedEntityId: input.relatedEntityId,
          },
        }),
      ),
    );

    await this.dispatch(input.userId, channels, input.title, input.body);

    return created;
  }

  private async dispatch(userId: string, channels: readonly string[], title: string, body: string) {
    const needsUser = channels.some((c) => c === 'sms' || c === 'whatsapp' || c === 'email');
    const needsTokens = channels.includes('push');

    const [user, deviceTokens] = await Promise.all([
      needsUser ? this.prisma.user.findUnique({ where: { id: userId } }) : Promise.resolve(null),
      needsTokens ? this.prisma.deviceToken.findMany({ where: { userId } }) : Promise.resolve([]),
    ]);

    await Promise.all(
      channels.map(async (channel) => {
        try {
          switch (channel) {
            case 'push':
              return await sendPush(deviceTokens.map((d) => d.token), title, body);
            case 'sms':
              return await sendSms(user?.phoneNumber ?? null, `${title}: ${body}`);
            case 'whatsapp':
              return await sendWhatsApp(user?.phoneNumber ?? null, `${title}: ${body}`);
            case 'email':
              return await sendEmail(user?.email ?? '', title, body);
            default:
              return;
          }
        } catch (err) {
          // A failed delivery shouldn't break the request that triggered the
          // notification (e.g. a booking confirmation) — log and move on.
          this.logger.error(`Failed to send ${channel} notification to user ${userId}: ${(err as Error).message}`);
        }
      }),
    );
  }

  async registerDeviceToken(userId: string, token: string, platform: string) {
    return this.prisma.deviceToken.upsert({
      where: { token },
      create: { userId, token, platform },
      update: { userId, platform },
    });
  }

  async unregisterDeviceToken(token: string) {
    await this.prisma.deviceToken.deleteMany({ where: { token } });
    return { success: true };
  }

  async listForUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { sentAt: 'desc' },
    });
  }

  async markRead(userId: string, id: string) {
    return this.prisma.notification.updateMany({
      where: { id, userId },
      data: { readAt: new Date() },
    });
  }

  async getPreferences(userId: string) {
    return this.prisma.notificationPreference.findMany({ where: { userId } });
  }

  async setPreference(userId: string, category: string, channel: string, enabled: boolean) {
    return this.prisma.notificationPreference.upsert({
      where: { userId_category_channel: { userId, category, channel: channel as never } },
      create: { userId, category, channel: channel as never, enabled },
      update: { enabled },
    });
  }
}
