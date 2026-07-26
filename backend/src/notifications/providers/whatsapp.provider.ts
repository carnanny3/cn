import { Logger } from '@nestjs/common';
import twilio from 'twilio';

const logger = new Logger('WhatsAppProvider');
let client: ReturnType<typeof twilio> | null | undefined;

function getClient() {
  if (client !== undefined) return client;
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  client = sid && token ? twilio(sid, token) : null;
  return client;
}

/** Requires a WhatsApp-approved Twilio sender (e.g. "whatsapp:+14155238886" for the sandbox) — see TWILIO_WHATSAPP_FROM_NUMBER. */
export async function sendWhatsApp(toPhoneNumber: string | null, body: string): Promise<void> {
  const twilioClient = getClient();
  const fromNumber = process.env.TWILIO_WHATSAPP_FROM_NUMBER;
  if (!twilioClient || !fromNumber || !toPhoneNumber) {
    logger.log(`[SIMULATED WHATSAPP] to=${toPhoneNumber ?? 'unknown'}: ${body}`);
    return;
  }

  await twilioClient.messages.create({
    to: `whatsapp:${toPhoneNumber}`,
    from: fromNumber,
    body,
  });
}
