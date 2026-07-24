import { createHash, randomInt, randomBytes, scryptSync, timingSafeEqual } from 'crypto';

export function hashValue(value: string): string {
  return createHash('sha256').update(value).digest('hex');
}

export function generateOtp(length = 6): string {
  let code = '';
  for (let i = 0; i < length; i++) {
    code += randomInt(0, 10).toString();
  }
  return code;
}

export function generateOpaqueToken(): string {
  return randomBytes(32).toString('hex');
}

const SCRYPT_KEYLEN = 64;

/** Password hashing via Node's built-in scrypt — no native module/build step required. */
export function hashPassword(password: string): string {
  const salt = randomBytes(16);
  const derivedKey = scryptSync(password, salt, SCRYPT_KEYLEN);
  return `${salt.toString('hex')}:${derivedKey.toString('hex')}`;
}

export function verifyPassword(password: string, storedHash: string): boolean {
  const [saltHex, keyHex] = storedHash.split(':');
  if (!saltHex || !keyHex) return false;
  const salt = Buffer.from(saltHex, 'hex');
  const storedKey = Buffer.from(keyHex, 'hex');
  const derivedKey = scryptSync(password, salt, SCRYPT_KEYLEN);
  if (derivedKey.length !== storedKey.length) return false;
  return timingSafeEqual(derivedKey, storedKey);
}
