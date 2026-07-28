import { BadRequestException, Injectable } from '@nestjs/common';
import { extname } from 'path';
import { v4 as uuidv4 } from 'uuid';
import { publicUrlFor, putObject, signedGetUrl } from './storage.provider';

/** Upload categories. Each one fixes its own key prefix, size cap, and visibility. */
export type StorageScope = 'vehicle-docs' | 'vehicle-photos' | 'listing-photos';

const IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MB = 1024 * 1024;

const SCOPES: Record<StorageScope, { mimeTypes: string[]; maxBytes: number; public: boolean }> = {
  // Registration and insurance papers carry personal data, so these are never
  // public — reads go through a short-lived signed URL instead.
  'vehicle-docs': { mimeTypes: [...IMAGE_TYPES, 'application/pdf'], maxBytes: 12 * MB, public: false },
  'vehicle-photos': { mimeTypes: IMAGE_TYPES, maxBytes: 8 * MB, public: true },
  'listing-photos': { mimeTypes: IMAGE_TYPES, maxBytes: 8 * MB, public: true },
};

const EXTENSIONS: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
  'application/pdf': '.pdf',
};

/** Signed document URLs are deliberately short-lived — long enough to open, not to share. */
const DOCUMENT_URL_TTL_SECONDS = 300;

export const MAX_LISTING_PHOTOS = 8;

export interface UploadedObject {
  key: string;
  url: string;
}

/**
 * Owns every object key in the system. Callers hand over bytes and a scope and
 * get back a key the server generated — clients never choose keys or URLs, which
 * is what stops an arbitrary URL being passed off as an uploaded document.
 */
@Injectable()
export class StorageService {
  async upload(
    file: { buffer: Buffer; mimetype: string; size: number; originalname?: string },
    scope: StorageScope,
    ownerId: string,
  ): Promise<UploadedObject> {
    const rules = SCOPES[scope];
    if (!rules.mimeTypes.includes(file.mimetype)) {
      throw new BadRequestException({
        code: 'UNSUPPORTED_FILE_TYPE',
        message: `Unsupported file type. Allowed: ${rules.mimeTypes.join(', ')}.`,
      });
    }
    if (file.size > rules.maxBytes) {
      throw new BadRequestException({
        code: 'FILE_TOO_LARGE',
        message: `File is too large. Maximum size is ${Math.floor(rules.maxBytes / MB)} MB.`,
      });
    }

    const key = this.buildKey(scope, ownerId, file.mimetype, file.originalname);
    await putObject(key, file.buffer, file.mimetype);
    return { key, url: rules.public ? publicUrlFor(key) : key };
  }

  buildKey(scope: StorageScope, ownerId: string, mimetype: string, originalname?: string): string {
    const ext = EXTENSIONS[mimetype] ?? (originalname ? extname(originalname).toLowerCase() : '');
    return `${scope}/${ownerId}/${uuidv4()}${ext}`;
  }

  /** Readable URL for a stored value: signed for private scopes, as-is for public ones. */
  viewUrlFor(storedValue: string): Promise<string> | string {
    if (/^https?:\/\//i.test(storedValue)) return storedValue;
    return signedGetUrl(storedValue, DOCUMENT_URL_TTL_SECONDS);
  }

  /**
   * True only for values this service handed out for the given scope. Used to
   * reject client-supplied photo URLs that point somewhere we never uploaded to.
   */
  isIssuedValue(value: string, scope: StorageScope): boolean {
    const prefix = `${scope}/`;
    if (value.startsWith(prefix)) return true;
    try {
      return new URL(value).pathname.includes(`/${prefix}`);
    } catch {
      return false;
    }
  }
}
