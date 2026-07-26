import { Logger } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

const logger = new Logger('EmailProvider');
let transporter: nodemailer.Transporter | null | undefined;

function getTransporter() {
  if (transporter !== undefined) return transporter;
  const host = process.env.SMTP_HOST;
  const port = process.env.SMTP_PORT;
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASSWORD;
  transporter = host && port && user && pass
    ? nodemailer.createTransport({ host, port: Number(port), secure: Number(port) === 465, auth: { user, pass } })
    : null;
  return transporter;
}

export async function sendEmail(toEmail: string, subject: string, body: string): Promise<void> {
  const mailer = getTransporter();
  const fromAddress = process.env.SMTP_FROM_ADDRESS;
  if (!mailer || !fromAddress) {
    logger.log(`[SIMULATED EMAIL] to=${toEmail}, subject="${subject}": ${body}`);
    return;
  }

  await mailer.sendMail({ from: fromAddress, to: toEmail, subject, text: body });
}
