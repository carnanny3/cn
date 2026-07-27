import { PrismaClient } from '@prisma/client';
import { scryptSync, randomBytes } from 'crypto';

const prisma = new PrismaClient();

const SEED_PASSWORD = 'CarNanny123!';

function hashPassword(password: string): string {
  const salt = randomBytes(16);
  const derivedKey = scryptSync(password, salt, 64);
  return `${salt.toString('hex')}:${derivedKey.toString('hex')}`;
}

/**
 * Narrow, production-safe counterpart to seed.ts: only creates the two new
 * finance roles. Unlike seed.ts, this never touches existing users (no
 * passwordHash reset risk) and doesn't insert any demo data.
 */
async function main() {
  const accountant = await prisma.user.upsert({
    where: { email: 'accountant@carnanny.app' },
    update: {},
    create: {
      email: 'accountant@carnanny.app',
      phoneNumber: '+971500000097',
      fullName: 'Car Nanny Accountant',
      passwordHash: hashPassword(SEED_PASSWORD),
      preferredLanguage: 'en',
      status: 'active',
      role: 'accountant',
    },
  });

  const accountsManager = await prisma.user.upsert({
    where: { email: 'accounts.manager@carnanny.app' },
    update: {},
    create: {
      email: 'accounts.manager@carnanny.app',
      phoneNumber: '+971500000098',
      fullName: 'Car Nanny Accounts Manager',
      passwordHash: hashPassword(SEED_PASSWORD),
      preferredLanguage: 'en',
      status: 'active',
      role: 'accounts_manager',
    },
  });

  console.log(`accountant: ${accountant.email} (created=${accountant.createdAt.toISOString() === accountant.updatedAt.toISOString()})`);
  console.log(`accounts manager: ${accountsManager.email} (created=${accountsManager.createdAt.toISOString() === accountsManager.updatedAt.toISOString()})`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
