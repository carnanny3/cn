import { PrismaClient } from '@prisma/client';
import { scryptSync, randomBytes } from 'crypto';

const prisma = new PrismaClient();

const SEED_PASSWORD = 'CarNanny123!';

function hashPassword(password: string): string {
  const salt = randomBytes(16);
  const derivedKey = scryptSync(password, salt, 64);
  return `${salt.toString('hex')}:${derivedKey.toString('hex')}`;
}

async function main() {
  console.log('Seeding Car Nanny dev database...');

  const customer = await prisma.user.upsert({
    where: { email: 'rashid@example.com' },
    update: { passwordHash: hashPassword(SEED_PASSWORD) },
    create: {
      email: 'rashid@example.com',
      phoneNumber: '+971500000001',
      fullName: 'Rashid Al Mansoori',
      passwordHash: hashPassword(SEED_PASSWORD),
      preferredLanguage: 'en',
      emirate: 'Dubai',
      status: 'active',
      role: 'customer',
    },
  });

  const admin = await prisma.user.upsert({
    where: { email: 'admin@carnanny.app' },
    update: { passwordHash: hashPassword(SEED_PASSWORD) },
    create: {
      email: 'admin@carnanny.app',
      phoneNumber: '+971500000099',
      fullName: 'Car Nanny Admin',
      passwordHash: hashPassword(SEED_PASSWORD),
      preferredLanguage: 'en',
      status: 'active',
      role: 'admin_super',
    },
  });

  const vehicle = await prisma.vehicle.upsert({
    where: { vin: 'JTDBR32E720123456' },
    update: {},
    create: {
      vin: 'JTDBR32E720123456',
      plateNumber: 'A 12345',
      emirateRegistered: 'Dubai',
      make: 'Toyota',
      model: 'Camry',
      year: 2019,
      bodyType: 'Sedan',
      fuelType: 'petrol',
      transmission: 'auto',
      gccSpec: true,
      color: 'White',
      mileageKm: 62000,
      owners: {
        create: { userId: customer.id, isPrimary: true, ownershipType: 'personal' },
      },
    },
  });

  await prisma.vehicleDocument.upsert({
    where: { id: 'seed-doc-registration' },
    update: { expiryDate: new Date('2027-01-10') },
    create: {
      id: 'seed-doc-registration',
      vehicleId: vehicle.id,
      type: 'registration',
      fileUrl: 'https://example.com/docs/registration.pdf',
      issuedDate: new Date('2026-01-10'),
      expiryDate: new Date('2027-01-10'),
      verified: true,
    },
  });

  await prisma.vehicleDocument.upsert({
    where: { id: 'seed-doc-insurance' },
    update: { expiryDate: new Date('2027-03-01') },
    create: {
      id: 'seed-doc-insurance',
      vehicleId: vehicle.id,
      type: 'insurance',
      fileUrl: 'https://example.com/docs/insurance.pdf',
      issuedDate: new Date('2026-03-01'),
      expiryDate: new Date('2027-03-01'),
      verified: true,
    },
  });

  const garagePartner = await prisma.partner.upsert({
    where: { id: 'seed-partner-garage' },
    update: {},
    create: {
      id: 'seed-partner-garage',
      businessName: 'Al Fahim Auto Care',
      partnerType: 'garage',
      status: 'verified',
      contactPhone: '+971501111111',
      ratingAvg: 4.8,
      cancellationRate: 0.02,
      latitude: 25.2048,
      longitude: 55.2708,
      verifiedAt: new Date(),
    },
  });

  await prisma.partnerService.upsert({
    where: { id: 'seed-service-oil-change' },
    update: {},
    create: {
      id: 'seed-service-oil-change',
      partnerId: garagePartner.id,
      serviceCategory: 'oil_change',
      price: 180,
      durationEstimateMinutes: 45,
      active: true,
    },
  });

  const inspectorPartner = await prisma.partner.upsert({
    where: { id: 'seed-partner-inspector' },
    update: {},
    create: {
      id: 'seed-partner-inspector',
      businessName: 'Car Nanny Certified Inspector — Ahmed K.',
      partnerType: 'inspector',
      status: 'verified',
      contactPhone: '+971502222222',
      ratingAvg: 4.9,
      cancellationRate: 0.01,
      latitude: 25.1972,
      longitude: 55.2744,
      verifiedAt: new Date(),
    },
  });

  const inspection = await prisma.inspection.upsert({
    where: { id: 'seed-inspection-1' },
    update: {},
    create: {
      id: 'seed-inspection-1',
      vehicleId: vehicle.id,
      requesterId: customer.id,
      inspectorId: inspectorPartner.id,
      status: 'completed',
      scheduledAt: new Date('2026-07-20T10:00:00+04:00'),
      locationLat: 25.2048,
      locationLng: 55.2708,
      locationAddress: 'Business Bay, Dubai',
      priceAmount: 349,
    },
  });

  await prisma.inspectionReport.upsert({
    where: { inspectionId: inspection.id },
    update: {},
    create: {
      inspectionId: inspection.id,
      overallScore: 7.8,
      overallStatus: 'amber',
      categoryScores: { engine: 8.5, brakes: 6.2, tires: 5.0, electrical: 9.0 },
      criticalDefectCount: 0,
      minorDefectCount: 4,
      estimatedRepairCost: 1200,
      aiSummary:
        'This vehicle is mechanically sound overall, with tire wear and brake pad thickness being the main items to negotiate on.',
      aiRecommendation: 'buy_after_negotiation',
    },
  });

  const warrantyProviderPartner = await prisma.partner.upsert({
    where: { id: 'seed-partner-warranty' },
    update: {},
    create: {
      id: 'seed-partner-warranty',
      businessName: 'Gulf Shield Warranty Co.',
      partnerType: 'warranty_provider',
      status: 'verified',
      contactEmail: 'claims@gulfshield.example',
      verifiedAt: new Date(),
    },
  });

  await prisma.warrantyPlan.upsert({
    where: { id: 'seed-warranty-plan-standard' },
    update: {},
    create: {
      id: 'seed-warranty-plan-standard',
      providerPartnerId: warrantyProviderPartner.id,
      name: 'Standard 12-Month Powertrain Warranty',
      coverageSummary: 'Covers engine, transmission, and drivetrain repairs for 12 months.',
      exclusions: 'Wear-and-tear items (brake pads, tires), cosmetic damage, and pre-existing conditions are not covered.',
      price: 899,
      eligibilityRules: { maxAgeYears: 8, maxMileageKm: 150000 },
    },
  });

  await prisma.insuranceProvider.upsert({
    where: { id: 'seed-insurance-provider-1' },
    update: {},
    create: { id: 'seed-insurance-provider-1', name: 'Al Noor Insurance', integrationType: 'manual' },
  });

  await prisma.partner.upsert({
    where: { id: 'seed-partner-roadside' },
    update: {},
    create: {
      id: 'seed-partner-roadside',
      businessName: 'Rapid Response Roadside',
      partnerType: 'roadside_provider',
      status: 'verified',
      contactPhone: '+971503333333',
      ratingAvg: 4.7,
      latitude: 25.2,
      longitude: 55.27,
      verifiedAt: new Date(),
    },
  });

  console.log('Seed complete.');
  console.log(`Sample customer: ${customer.email} / password: ${SEED_PASSWORD}`);
  console.log(`Sample admin: ${admin.email} / password: ${SEED_PASSWORD}`);
  console.log(`Sample vehicle: ${vehicle.year} ${vehicle.make} ${vehicle.model} (id=${vehicle.id})`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
