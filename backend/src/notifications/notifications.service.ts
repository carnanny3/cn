import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

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
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Fans out to every enabled channel for this user/category (default: push
   * only, per notification_preferences). Actual delivery (FCM/SMS/WhatsApp)
   * is stubbed to a console log — wire real providers here before production.
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

    for (const n of created) {
      // eslint-disable-next-line no-console
      console.log(`[DEV NOTIFICATION -> ${n.channel}] user=${input.userId}: ${n.title} — ${n.body}`);
    }

    return created;
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
