import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { VehiclesService } from '../vehicles/vehicles.service';
import { CreateRecordDto } from './dto/create-record.dto';
import { UpdateRecordDto } from './dto/update-record.dto';
import { CreateFuelEntryDto } from './dto/create-fuel-entry.dto';
import { UpdateFuelEntryDto } from './dto/update-fuel-entry.dto';
import { CreateReminderDto } from './dto/create-reminder.dto';
import { UpdateReminderDto } from './dto/update-reminder.dto';
import { calculateFuelEconomy } from './fuel-economy.util';
import { nextOccurrence, reminderStatus, todayInUae, urgencyRank } from './reminder.util';
import { CostItem, summarizeCosts } from './cost-summary.util';
import { toCsv } from './csv.util';

type UploadedImage = { buffer: Buffer; mimetype: string; size: number; originalname?: string };

const MAX_PHOTOS_PER_RECORD = 6;

/** `undefined` leaves a column alone on update; `null` (sent explicitly) clears it. */
function optionalDate(value: string | null | undefined): Date | null | undefined {
  if (value === undefined) return undefined;
  return value === null ? null : new Date(value);
}

const notFound = (what: string) =>
  new NotFoundException({
    code: `${what.toUpperCase().replace(/ /g, '_')}_NOT_FOUND`,
    message: `${what[0].toUpperCase()}${what.slice(1)} not found.`,
  });

/**
 * The owner's own logbook for a vehicle: service/repair/upgrade/fee entries with
 * receipt photos, fuel fill-ups, and reminders, plus the summaries derived from
 * them. Every entry point checks vehicle ownership first, and every row lookup
 * is scoped to that vehicle, so an ID from another vehicle simply isn't found.
 */
@Injectable()
export class LogbookService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly vehicles: VehiclesService,
    private readonly storage: StorageService,
  ) {}

  // ---------- Odometer ----------

  /** Highest reading known anywhere: the vehicle itself, its logbook, or its fuel log. */
  async currentOdometer(vehicleId: string): Promise<number> {
    const [vehicle, record, fuel] = await Promise.all([
      this.prisma.vehicle.findUnique({ where: { id: vehicleId }, select: { mileageKm: true } }),
      this.prisma.vehicleRecord.aggregate({ where: { vehicleId }, _max: { odometerKm: true } }),
      this.prisma.fuelEntry.aggregate({ where: { vehicleId }, _max: { odometerKm: true } }),
    ]);
    return Math.max(vehicle?.mileageKm ?? 0, record._max.odometerKm ?? 0, fuel._max.odometerKm ?? 0);
  }

  /** Raise the vehicle's mileage to a newly logged reading; never lowers it. */
  private async raiseMileage(vehicleId: string, odometerKm?: number | null) {
    if (odometerKm === undefined || odometerKm === null) return;
    await this.prisma.vehicle.updateMany({
      where: { id: vehicleId, OR: [{ mileageKm: null }, { mileageKm: { lt: odometerKm } }] },
      data: { mileageKm: odometerKm },
    });
  }

  // ---------- Records ----------

  /**
   * Logbook entries plus completed Car Nanny service bookings, newest first.
   * Bookings are read-only here (`source: 'booking'`) — they're managed in Bookings.
   */
  async listRecords(userId: string, vehicleId: string) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const [records, bookings] = await Promise.all([
      this.prisma.vehicleRecord.findMany({
        where: { vehicleId },
        include: { photos: { orderBy: { createdAt: 'asc' } } },
        orderBy: [{ date: 'desc' }, { createdAt: 'desc' }],
      }),
      this.completedBookings(vehicleId),
    ]);

    const own = await Promise.all(records.map((r) => this.withPhotoUrls(r)));
    const fromBookings = bookings.map((b) => ({
      id: b.id,
      source: 'booking' as const,
      type: 'service' as const,
      date: b.scheduledAt,
      odometerKm: null,
      title: b.serviceCategory ?? 'Car Nanny service',
      partnerName: b.partner?.businessName ?? null,
      cost: b.totalAmount,
      currency: b.currency,
      notes: null,
      photos: [],
    }));
    return [...own, ...fromBookings].sort((a, b) => b.date.getTime() - a.date.getTime());
  }

  async createRecord(userId: string, vehicleId: string, dto: CreateRecordDto) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const record = await this.prisma.vehicleRecord.create({
      data: {
        vehicleId,
        type: dto.type,
        date: new Date(dto.date),
        title: dto.title.trim(),
        odometerKm: dto.odometerKm,
        cost: dto.cost ?? 0,
        notes: dto.notes,
        createdBy: userId,
      },
      include: { photos: true },
    });
    await this.raiseMileage(vehicleId, dto.odometerKm);
    return this.withPhotoUrls(record);
  }

  async updateRecord(userId: string, vehicleId: string, recordId: string, dto: UpdateRecordDto) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    await this.findRecord(vehicleId, recordId);
    const record = await this.prisma.vehicleRecord.update({
      where: { id: recordId },
      data: {
        type: dto.type,
        date: dto.date ? new Date(dto.date) : undefined,
        title: dto.title?.trim(),
        odometerKm: dto.odometerKm,
        cost: dto.cost,
        notes: dto.notes,
      },
      include: { photos: { orderBy: { createdAt: 'asc' } } },
    });
    await this.raiseMileage(vehicleId, dto.odometerKm);
    return this.withPhotoUrls(record);
  }

  async deleteRecord(userId: string, vehicleId: string, recordId: string) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const record = await this.findRecord(vehicleId, recordId);
    await this.prisma.vehicleRecord.delete({ where: { id: record.id } }); // photos cascade
    await this.storage.removeMany(record.photos.map((p) => p.fileKey));
    return { deleted: true };
  }

  async addRecordPhoto(userId: string, vehicleId: string, recordId: string, file: UploadedImage) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const record = await this.findRecord(vehicleId, recordId);
    if (record.photos.length >= MAX_PHOTOS_PER_RECORD) {
      throw new BadRequestException({
        code: 'TOO_MANY_PHOTOS',
        message: `A record can have at most ${MAX_PHOTOS_PER_RECORD} photos.`,
      });
    }
    const { key } = await this.storage.upload(file, 'vehicle-receipts', vehicleId);
    const photo = await this.prisma.vehicleRecordPhoto.create({ data: { recordId, fileKey: key } });
    return { id: photo.id, createdAt: photo.createdAt, viewUrl: await this.storage.viewUrlFor(photo.fileKey) };
  }

  async deleteRecordPhoto(userId: string, vehicleId: string, recordId: string, photoId: string) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    await this.findRecord(vehicleId, recordId);
    const photo = await this.prisma.vehicleRecordPhoto.findFirst({ where: { id: photoId, recordId } });
    if (!photo) throw notFound('photo');
    await this.prisma.vehicleRecordPhoto.delete({ where: { id: photo.id } });
    await this.storage.removeMany([photo.fileKey]);
    return { deleted: true };
  }

  private async findRecord(vehicleId: string, recordId: string) {
    const record = await this.prisma.vehicleRecord.findFirst({
      where: { id: recordId, vehicleId },
      include: { photos: true },
    });
    if (!record) throw notFound('record');
    return record;
  }

  private async withPhotoUrls<T extends { photos: { id: string; fileKey: string; createdAt: Date }[] }>(record: T) {
    const photos = await Promise.all(
      record.photos.map(async (p) => ({ id: p.id, createdAt: p.createdAt, viewUrl: await this.storage.viewUrlFor(p.fileKey) })),
    );
    return { ...record, source: 'logbook' as const, photos };
  }

  private completedBookings(vehicleId: string) {
    return this.prisma.booking.findMany({
      where: { vehicleId, bookingType: 'service', status: 'completed' },
      include: { partner: { select: { businessName: true } } },
      orderBy: { scheduledAt: 'desc' },
    });
  }

  // ---------- Fuel ----------

  async listFuel(userId: string, vehicleId: string) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const entries = await this.prisma.fuelEntry.findMany({ where: { vehicleId } });
    const economy = calculateFuelEconomy(entries);
    return {
      averageKmPerLiter: economy.averageKmPerLiter,
      averageLitersPer100Km: economy.averageLitersPer100Km,
      totalLiters: economy.totalLiters,
      totalCost: economy.totalCost,
      entries: economy.fills.map((f) => ({
        ...f.entry,
        distanceKm: f.distanceKm,
        kmPerLiter: f.kmPerLiter,
        litersPer100Km: f.litersPer100Km,
        pricePerLiter: f.pricePerLiter,
      })),
    };
  }

  async createFuel(userId: string, vehicleId: string, dto: CreateFuelEntryDto) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const entry = await this.prisma.fuelEntry.create({
      data: {
        vehicleId,
        date: new Date(dto.date),
        odometerKm: dto.odometerKm,
        liters: dto.liters,
        cost: dto.cost ?? 0,
        fullTank: dto.fullTank ?? true,
        missedPrevious: dto.missedPrevious ?? false,
        notes: dto.notes,
        createdBy: userId,
      },
    });
    await this.raiseMileage(vehicleId, dto.odometerKm);
    return entry;
  }

  async updateFuel(userId: string, vehicleId: string, entryId: string, dto: UpdateFuelEntryDto) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    await this.findFuel(vehicleId, entryId);
    const entry = await this.prisma.fuelEntry.update({
      where: { id: entryId },
      data: {
        date: dto.date ? new Date(dto.date) : undefined,
        odometerKm: dto.odometerKm,
        liters: dto.liters,
        cost: dto.cost,
        fullTank: dto.fullTank,
        missedPrevious: dto.missedPrevious,
        notes: dto.notes,
      },
    });
    await this.raiseMileage(vehicleId, dto.odometerKm);
    return entry;
  }

  async deleteFuel(userId: string, vehicleId: string, entryId: string) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    await this.findFuel(vehicleId, entryId);
    await this.prisma.fuelEntry.delete({ where: { id: entryId } });
    return { deleted: true };
  }

  private async findFuel(vehicleId: string, entryId: string) {
    const entry = await this.prisma.fuelEntry.findFirst({ where: { id: entryId, vehicleId } });
    if (!entry) throw notFound('fuel entry');
    return entry;
  }

  // ---------- Reminders ----------

  async listReminders(userId: string, vehicleId: string) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const [reminders, odometer] = await Promise.all([
      this.prisma.vehicleReminder.findMany({ where: { vehicleId }, orderBy: { createdAt: 'desc' } }),
      this.currentOdometer(vehicleId),
    ]);
    const today = todayInUae();
    return reminders
      .map((r) => ({ ...r, ...reminderStatus(r, odometer, today) }))
      .sort(
        (a, b) =>
          urgencyRank(b.urgency) - urgencyRank(a.urgency) ||
          (a.daysLeft ?? Number.MAX_SAFE_INTEGER) - (b.daysLeft ?? Number.MAX_SAFE_INTEGER) ||
          (a.kmLeft ?? Number.MAX_SAFE_INTEGER) - (b.kmLeft ?? Number.MAX_SAFE_INTEGER),
      );
  }

  async createReminder(userId: string, vehicleId: string, dto: CreateReminderDto) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    this.assertHasTarget(dto.dueDate, dto.dueOdometerKm);
    return this.prisma.vehicleReminder.create({
      data: {
        vehicleId,
        title: dto.title.trim(),
        dueDate: optionalDate(dto.dueDate),
        dueOdometerKm: dto.dueOdometerKm,
        repeatMonths: dto.repeatMonths,
        repeatKm: dto.repeatKm,
        notes: dto.notes,
        createdBy: userId,
      },
    });
  }

  async updateReminder(userId: string, vehicleId: string, reminderId: string, dto: UpdateReminderDto) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const existing = await this.findReminder(vehicleId, reminderId);
    const dueDate = optionalDate(dto.dueDate);
    this.assertHasTarget(
      dueDate === undefined ? existing.dueDate : dueDate,
      dto.dueOdometerKm === undefined ? existing.dueOdometerKm : dto.dueOdometerKm,
    );
    return this.prisma.vehicleReminder.update({
      where: { id: reminderId },
      data: {
        title: dto.title?.trim(),
        dueDate,
        dueOdometerKm: dto.dueOdometerKm,
        repeatMonths: dto.repeatMonths,
        repeatKm: dto.repeatKm,
        notes: dto.notes,
      },
    });
  }

  /** Marks a reminder done and, if it repeats, schedules the next one. */
  async completeReminder(userId: string, vehicleId: string, reminderId: string) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const reminder = await this.findReminder(vehicleId, reminderId);
    if (reminder.completedAt) {
      throw new BadRequestException({ code: 'REMINDER_ALREADY_DONE', message: 'This reminder is already done.' });
    }
    const today = todayInUae();
    const next = nextOccurrence(reminder, await this.currentOdometer(vehicleId), today);
    return this.prisma.$transaction(async (tx) => {
      const completed = await tx.vehicleReminder.update({
        where: { id: reminder.id },
        data: { completedAt: new Date() },
      });
      const scheduled = next
        ? await tx.vehicleReminder.create({
            data: {
              vehicleId,
              title: reminder.title,
              notes: reminder.notes,
              repeatMonths: reminder.repeatMonths,
              repeatKm: reminder.repeatKm,
              dueDate: next.dueDate,
              dueOdometerKm: next.dueOdometerKm,
              createdBy: userId,
            },
          })
        : null;
      return { completed, next: scheduled };
    });
  }

  async deleteReminder(userId: string, vehicleId: string, reminderId: string) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    await this.findReminder(vehicleId, reminderId);
    await this.prisma.vehicleReminder.delete({ where: { id: reminderId } });
    return { deleted: true };
  }

  private assertHasTarget(dueDate: unknown, dueOdometerKm: unknown) {
    if ((dueDate === undefined || dueDate === null) && (dueOdometerKm === undefined || dueOdometerKm === null)) {
      throw new BadRequestException({
        code: 'REMINDER_NEEDS_TARGET',
        message: 'Set a due date, a due odometer reading, or both.',
      });
    }
  }

  private async findReminder(vehicleId: string, reminderId: string) {
    const reminder = await this.prisma.vehicleReminder.findFirst({ where: { id: reminderId, vehicleId } });
    if (!reminder) throw notFound('reminder');
    return reminder;
  }

  /**
   * Open reminders that need action (overdue, due soon, upcoming) across every
   * vehicle the user owns — what the Home screen shows.
   */
  async attention(userId: string) {
    const owned = await this.prisma.vehicleOwner.findMany({
      where: { userId },
      include: { vehicle: { select: { id: true, make: true, model: true, year: true, plateNumber: true } } },
    });
    const today = todayInUae();
    const items = [];
    for (const { vehicle } of owned) {
      const [reminders, odometer] = await Promise.all([
        this.prisma.vehicleReminder.findMany({ where: { vehicleId: vehicle.id, completedAt: null } }),
        this.currentOdometer(vehicle.id),
      ]);
      for (const r of reminders) {
        const status = reminderStatus(r, odometer, today);
        if (status.urgency === 'later') continue;
        items.push({ ...r, ...status, vehicle });
      }
    }
    return items.sort((a, b) => urgencyRank(b.urgency) - urgencyRank(a.urgency));
  }

  // ---------- Summary & export ----------

  async summary(userId: string, vehicleId: string) {
    await this.vehicles.assertOwnership(userId, vehicleId);
    const [records, fuel, bookings, reminders, odometer, firstReadings] = await Promise.all([
      this.prisma.vehicleRecord.findMany({ where: { vehicleId }, select: { type: true, date: true, cost: true } }),
      this.prisma.fuelEntry.findMany({ where: { vehicleId } }),
      this.completedBookings(vehicleId),
      this.prisma.vehicleReminder.findMany({ where: { vehicleId, completedAt: null } }),
      this.currentOdometer(vehicleId),
      Promise.all([
        this.prisma.vehicleRecord.aggregate({ where: { vehicleId }, _min: { odometerKm: true } }),
        this.prisma.fuelEntry.aggregate({ where: { vehicleId }, _min: { odometerKm: true } }),
      ]),
    ]);

    const today = todayInUae();
    const items: CostItem[] = [
      ...records.map((r) => ({ category: r.type, date: r.date, amount: r.cost })),
      ...fuel.map((f) => ({ category: 'fuel' as const, date: f.date, amount: f.cost })),
      ...bookings.map((b) => ({ category: 'car_nanny' as const, date: b.scheduledAt, amount: b.totalAmount })),
    ];
    const costs = summarizeCosts(items, today);
    const economy = calculateFuelEconomy(fuel);

    // Distance the logbook actually covers: from the lowest logged reading to now.
    const lows = firstReadings.map((a) => a._min.odometerKm).filter((v): v is number => v !== null);
    const distanceTrackedKm = lows.length ? Math.max(0, odometer - Math.min(...lows)) : 0;

    const reminderCounts = { overdue: 0, due_soon: 0, upcoming: 0, later: 0 };
    for (const r of reminders) {
      const { urgency } = reminderStatus(r, odometer, today);
      if (urgency !== 'done') reminderCounts[urgency] += 1;
    }

    return {
      currency: 'AED',
      currentOdometerKm: odometer,
      distanceTrackedKm,
      costPerKm: distanceTrackedKm > 0 ? costs.total / distanceTrackedKm : null,
      ...costs,
      fuel: {
        averageKmPerLiter: economy.averageKmPerLiter,
        averageLitersPer100Km: economy.averageLitersPer100Km,
        totalLiters: economy.totalLiters,
        fillUps: fuel.length,
      },
      reminderCounts,
    };
  }

  async exportCsv(userId: string, vehicleId: string, kind: 'records' | 'fuel'): Promise<{ filename: string; csv: string }> {
    const vehicle = await this.vehicles.findOneForUser(userId, vehicleId);
    const slug = `${vehicle.make}-${vehicle.model}-${vehicle.plateNumber}`.replace(/[^\w-]+/g, '_');

    if (kind === 'fuel') {
      const { entries } = await this.listFuel(userId, vehicleId);
      return {
        filename: `${slug}-fuel.csv`,
        csv: toCsv(
          ['date', 'odometer_km', 'liters', 'cost_aed', 'full_tank', 'missed_previous', 'distance_km', 'km_per_liter', 'l_per_100km', 'notes'],
          entries.map((e) => [e.date, e.odometerKm, e.liters, e.cost, e.fullTank, e.missedPrevious, e.distanceKm, e.kmPerLiter, e.litersPer100Km, e.notes]),
        ),
      };
    }

    const records = await this.listRecords(userId, vehicleId);
    return {
      filename: `${slug}-records.csv`,
      csv: toCsv(
        ['date', 'source', 'type', 'title', 'odometer_km', 'cost_aed', 'notes'],
        records.map((r) => [r.date, r.source, r.type, r.title, r.odometerKm, r.cost, r.notes]),
      ),
    };
  }
}
