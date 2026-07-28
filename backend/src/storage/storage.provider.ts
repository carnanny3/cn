import { Logger, ServiceUnavailableException } from '@nestjs/common';
import { mkdir, writeFile } from 'fs/promises';
import { dirname, join } from 'path';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const logger = new Logger('StorageProvider');

/** Where the no-credentials fallback writes files, served by main.ts at /uploads. */
export const LOCAL_UPLOAD_DIR = join(process.cwd(), 'uploads');

let client: S3Client | null | undefined;

/**
 * Lazily builds the R2 client from the R2_* env vars. Returns null (cached) when
 * they aren't set, which switches every operation here to writing under
 * ./uploads and serving from /uploads instead — same "works without credentials"
 * convention as the notification providers and PaymentsService.
 */
function getClient(): S3Client | null {
  if (client !== undefined) return client;
  const accountId = process.env.R2_ACCOUNT_ID;
  const accessKeyId = process.env.R2_ACCESS_KEY_ID;
  const secretAccessKey = process.env.R2_SECRET_ACCESS_KEY;
  if (!accountId || !accessKeyId || !secretAccessKey || !process.env.R2_BUCKET) {
    client = null;
    return client;
  }
  client = new S3Client({
    region: 'auto',
    endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
    credentials: { accessKeyId, secretAccessKey },
  });
  return client;
}

export function isRemoteConfigured(): boolean {
  return getClient() !== null;
}

/**
 * The local-disk fallback is a development convenience only. In production the
 * container filesystem is ephemeral and the URLs it produces point at
 * localhost, so accepting an upload there would lose the file on the next
 * deploy and hand the customer a dead link. Refusing is the honest outcome.
 */
function assertUsableFallback(): void {
  if (process.env.NODE_ENV === 'production') {
    throw new ServiceUnavailableException({
      code: 'STORAGE_NOT_CONFIGURED',
      message: 'File storage is not available right now. Please try again later.',
    });
  }
}

export async function putObject(key: string, body: Buffer, contentType: string): Promise<void> {
  const r2 = getClient();
  if (!r2) {
    assertUsableFallback();
    const target = join(LOCAL_UPLOAD_DIR, key);
    await mkdir(dirname(target), { recursive: true });
    await writeFile(target, body);
    logger.log(`[SIMULATED UPLOAD] ${key} (${body.length} bytes, ${contentType}) -> ${target}`);
    return;
  }
  await r2.send(
    new PutObjectCommand({
      Bucket: process.env.R2_BUCKET,
      Key: key,
      Body: body,
      ContentType: contentType,
    }),
  );
}

/**
 * Time-limited read URL, used for private objects (vehicle documents) so their
 * contents are never reachable from a guessed or leaked permanent link.
 */
export async function signedGetUrl(key: string, ttlSeconds: number): Promise<string> {
  const r2 = getClient();
  if (!r2) return `${localBaseUrl()}/uploads/${key}`;
  return getSignedUrl(
    r2,
    new GetObjectCommand({ Bucket: process.env.R2_BUCKET, Key: key }),
    { expiresIn: ttlSeconds },
  );
}

/** Permanent URL for objects meant to be public (listing and vehicle photos). */
export function publicUrlFor(key: string): string {
  const base = process.env.R2_PUBLIC_BASE_URL;
  if (!base) return `${localBaseUrl()}/uploads/${key}`;
  return `${base.replace(/\/$/, '')}/${key}`;
}

function localBaseUrl(): string {
  const port = process.env.PORT ?? '3000';
  return (process.env.PUBLIC_BASE_URL ?? `http://localhost:${port}`).replace(/\/$/, '');
}
