export type ReminderUrgency = 'overdue' | 'due_soon' | 'upcoming' | 'later' | 'done';

export interface ReminderLike {
  dueDate: Date | null;
  dueOdometerKm: number | null;
  repeatMonths: number | null;
  repeatKm: number | null;
  completedAt: Date | null;
}

export interface ReminderStatus {
  urgency: ReminderUrgency;
  daysLeft: number | null;
  kmLeft: number | null;
}

/** Thresholds a reminder moves through as its date or odometer target approaches. */
const DUE_SOON_DAYS = 7;
const UPCOMING_DAYS = 30;
const DUE_SOON_KM = 500;
const UPCOMING_KM = 1500;

const RANK: Record<ReminderUrgency, number> = { done: -1, later: 0, upcoming: 1, due_soon: 2, overdue: 3 };

/** Today's calendar date in the UAE, as a UTC-midnight Date to compare with @db.Date columns. */
export function todayInUae(now = new Date()): Date {
  const iso = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Dubai' }).format(now);
  return new Date(`${iso}T00:00:00.000Z`);
}

export function addMonths(date: Date, months: number): Date {
  const y = date.getUTCFullYear();
  const m = date.getUTCMonth() + months;
  const lastDay = new Date(Date.UTC(y, m + 1, 0)).getUTCDate();
  return new Date(Date.UTC(y, m, Math.min(date.getUTCDate(), lastDay)));
}

/**
 * Where a reminder stands. A reminder can be due by date, by odometer, or both;
 * whichever target is closer decides, so "every 6 months or 10,000 km" fires on
 * whichever comes first.
 */
export function reminderStatus(reminder: ReminderLike, currentOdometerKm: number, today: Date): ReminderStatus {
  const daysLeft = reminder.dueDate ? Math.round((reminder.dueDate.getTime() - today.getTime()) / 86_400_000) : null;
  const kmLeft = reminder.dueOdometerKm !== null ? reminder.dueOdometerKm - currentOdometerKm : null;
  if (reminder.completedAt) return { urgency: 'done', daysLeft, kmLeft };

  let urgency: ReminderUrgency = 'later';
  const raise = (level: ReminderUrgency) => {
    if (RANK[level] > RANK[urgency]) urgency = level;
  };
  if (daysLeft !== null) {
    if (daysLeft < 0) raise('overdue');
    else if (daysLeft <= DUE_SOON_DAYS) raise('due_soon');
    else if (daysLeft <= UPCOMING_DAYS) raise('upcoming');
  }
  if (kmLeft !== null) {
    if (kmLeft <= 0) raise('overdue');
    else if (kmLeft <= DUE_SOON_KM) raise('due_soon');
    else if (kmLeft <= UPCOMING_KM) raise('upcoming');
  }
  return { urgency, daysLeft, kmLeft };
}

/**
 * The next occurrence of a repeating reminder, counted from when it was actually
 * done (today, at this odometer) rather than from its old due point — servicing
 * a month late pushes the next one back, just as it does in a real service book.
 * Returns null for one-off reminders.
 */
export function nextOccurrence(
  reminder: ReminderLike,
  currentOdometerKm: number,
  today: Date,
): { dueDate: Date | null; dueOdometerKm: number | null } | null {
  if (!reminder.repeatMonths && !reminder.repeatKm) return null;
  return {
    dueDate: reminder.repeatMonths ? addMonths(today, reminder.repeatMonths) : null,
    dueOdometerKm: reminder.repeatKm ? currentOdometerKm + reminder.repeatKm : null,
  };
}

export function urgencyRank(urgency: ReminderUrgency): number {
  return RANK[urgency];
}
