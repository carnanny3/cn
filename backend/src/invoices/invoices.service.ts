import { Injectable, NotFoundException, StreamableFile } from '@nestjs/common';
import { randomBytes } from 'crypto';
import type { Readable } from 'stream';
import PDFDocument from 'pdfkit';
import { Invoice, RelatedEntityType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const RELATED_ENTITY_LABELS: Record<RelatedEntityType, string> = {
  booking: 'Service Booking',
  inspection: 'Vehicle Inspection',
  warranty_policy: 'Warranty Policy',
  insurance_policy: 'Insurance Policy',
  roadside_request: 'Roadside Assistance',
};

function generateInvoiceNumber(): string {
  return `INV-${randomBytes(4).toString('hex').toUpperCase()}`;
}

@Injectable()
export class InvoicesService {
  constructor(private readonly prisma: PrismaService) {}

  /** Idempotent — a payment that already has an invoice is returned as-is rather than duplicated. */
  async generateForPayment(paymentId: string): Promise<Invoice> {
    const existing = await this.prisma.invoice.findUnique({ where: { paymentId } });
    if (existing) return existing;

    const payment = await this.prisma.payment.findUnique({ where: { id: paymentId } });
    if (!payment) throw new NotFoundException({ code: 'PAYMENT_NOT_FOUND', message: 'Payment not found.' });

    return this.prisma.invoice.create({
      data: {
        invoiceNumber: generateInvoiceNumber(),
        paymentId: payment.id,
        customerId: payment.customerId,
        description: RELATED_ENTITY_LABELS[payment.relatedEntityType],
        subtotal: payment.amount - payment.vatAmount,
        vatAmount: payment.vatAmount,
        totalAmount: payment.amount,
        currency: payment.currency,
      },
    });
  }

  async markRefunded(paymentId: string): Promise<void> {
    await this.prisma.invoice.updateMany({ where: { paymentId }, data: { status: 'refunded' } });
  }

  listAll(status?: string) {
    return this.prisma.invoice.findMany({
      where: status ? { status: status as never } : undefined,
      orderBy: { issuedAt: 'desc' },
      include: { customer: { select: { fullName: true, email: true } } },
    });
  }

  async findOne(id: string) {
    const invoice = await this.prisma.invoice.findUnique({
      where: { id },
      include: { customer: { select: { fullName: true, email: true } } },
    });
    if (!invoice) throw new NotFoundException({ code: 'INVOICE_NOT_FOUND', message: 'Invoice not found.' });
    return invoice;
  }

  async renderPdf(id: string): Promise<StreamableFile> {
    const invoice = await this.findOne(id);
    const doc = new PDFDocument({ size: 'A4', margin: 50 });

    doc.fontSize(20).text('Car Nanny', { continued: false });
    doc.fontSize(10).fillColor('#666').text('Tax Invoice');
    doc.moveDown(1.5);

    doc.fillColor('#000').fontSize(11);
    doc.text(`Invoice #: ${invoice.invoiceNumber}`);
    doc.text(`Date: ${invoice.issuedAt.toDateString()}`);
    doc.text(`Status: ${invoice.status}`);
    doc.moveDown();
    doc.text(`Billed to: ${invoice.customer.fullName}`);
    doc.text(invoice.customer.email);
    doc.moveDown(1.5);

    doc.fontSize(12).text(invoice.description);
    doc.moveDown(0.5);
    doc.fontSize(11);
    doc.text(`Subtotal: ${invoice.currency} ${invoice.subtotal.toFixed(2)}`);
    doc.text(`VAT: ${invoice.currency} ${invoice.vatAmount.toFixed(2)}`);
    doc.fontSize(13).text(`Total: ${invoice.currency} ${invoice.totalAmount.toFixed(2)}`, { underline: true });

    doc.end();
    return new StreamableFile(doc as unknown as Readable, {
      type: 'application/pdf',
      disposition: `attachment; filename="${invoice.invoiceNumber}.pdf"`,
    });
  }
}
