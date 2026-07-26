import { Logger } from '@nestjs/common';
import { cert, initializeApp, type App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

const logger = new Logger('PushProvider');
let app: App | null | undefined;

/** Lazily initializes the Firebase Admin app from FIREBASE_SERVICE_ACCOUNT_JSON (the full service-account JSON, as a single-line env var). Returns null (cached) if not configured. */
function getApp(): App | null {
  if (app !== undefined) return app;
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!json) {
    app = null;
    return app;
  }
  app = initializeApp({ credential: cert(JSON.parse(json)) });
  return app;
}

export async function sendPush(deviceTokens: string[], title: string, body: string): Promise<void> {
  const firebaseApp = getApp();
  if (!firebaseApp || deviceTokens.length === 0) {
    logger.log(`[SIMULATED PUSH] ${deviceTokens.length} device(s): ${title} — ${body}`);
    return;
  }

  await getMessaging(firebaseApp).sendEachForMulticast({
    tokens: deviceTokens,
    notification: { title, body },
  });
}
