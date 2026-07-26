import { Logger } from '@nestjs/common';
import twilio from 'twilio';

const logger = new Logger('SmsProvider');
let client: ReturnType<typeof twilio> | null | undefined;

function getClient() {
  if (client !== undefined) return client;
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  client = sid && token ? twilio(sid, token) : null;
  return client;
}

export async function sendSms(toPhoneNumber: string | null, body: string): Promise<void> {
  const twilioClient = getClient();
  const fromNumber = process.env.TWILIO_SMS_FROM_NUMBER;
  if (!twilioClient || !fromNumber || !toPhoneNumber) {
    logger.log(`[SIMULATED SMS] to=${toPhoneNumber ?? 'unknown'}: ${body}`);
    return;
  }

  await twilioClient.messages.create({ to: toPhoneNumber, from: fromNumber, body });
}
