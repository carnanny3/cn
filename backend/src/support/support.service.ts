import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SupportService {
  constructor(private readonly prisma: PrismaService) {}

  async createTicket(userId: string, category: string, subject: string, message: string) {
    return this.prisma.supportTicket.create({
      data: {
        userId,
        category,
        subject,
        messages: { create: { authorId: userId, authorRole: 'user', content: message } },
      },
      include: { messages: true },
    });
  }

  async listMyTickets(userId: string) {
    return this.prisma.supportTicket.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async listAllTickets(status?: string) {
    return this.prisma.supportTicket.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { createdAt: 'desc' },
      include: { user: { select: { fullName: true, email: true } } },
    });
  }

  async getTicket(userId: string | null, id: string) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id },
      include: { messages: { orderBy: { createdAt: 'asc' } } },
    });
    if (!ticket) throw new NotFoundException({ code: 'TICKET_NOT_FOUND', message: 'Support ticket not found.' });
    if (userId && ticket.userId !== userId) {
      throw new ForbiddenException({ code: 'NOT_TICKET_OWNER', message: 'You do not have access to this ticket.' });
    }
    return ticket;
  }

  async addMessage(callerId: string, callerRole: string, ticketId: string, content: string) {
    const isAdmin = callerRole !== 'customer' && callerRole !== 'partner';
    await this.getTicket(isAdmin ? null : callerId, ticketId);

    const message = await this.prisma.supportTicketMessage.create({
      data: { ticketId, authorId: callerId, authorRole: isAdmin ? 'admin' : 'user', content },
    });

    // A customer reply reopens a resolved/closed ticket; an admin reply moves a fresh ticket into progress.
    if (isAdmin) {
      await this.prisma.supportTicket.updateMany({
        where: { id: ticketId, status: 'open' },
        data: { status: 'in_progress' },
      });
    } else {
      await this.prisma.supportTicket.updateMany({
        where: { id: ticketId, status: { in: ['resolved', 'closed'] } },
        data: { status: 'open' },
      });
    }

    return message;
  }

  async updateStatus(ticketId: string, status: string, assignedAdminId?: string) {
    return this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: { status: status as never, ...(assignedAdminId ? { assignedAdminId } : {}) },
    });
  }
}
