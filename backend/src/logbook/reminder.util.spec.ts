import { addMonths, nextOccurrence, ReminderLike, reminderStatus, todayInUae } from './reminder.util';

const today = new Date('2026-09-23T00:00:00.000Z');

function reminder(overrides: Partial<ReminderLike> = {}): ReminderLike {
  return { dueDate: null, dueOdometerKm: null, repeatMonths: null, repeatKm: null, completedAt: null, ...overrides };
}

describe('reminderStatus', () => {
  it('grades date-based reminders by days left', () => {
    expect(reminderStatus(reminder({ dueDate: new Date('2026-09-20') }), 0, today).urgency).toBe('overdue');
    expect(reminderStatus(reminder({ dueDate: new Date('2026-09-27') }), 0, today).urgency).toBe('due_soon');
    expect(reminderStatus(reminder({ dueDate: new Date('2026-10-15') }), 0, today).urgency).toBe('upcoming');
    expect(reminderStatus(reminder({ dueDate: new Date('2027-01-01') }), 0, today).urgency).toBe('later');
  });

  it('grades odometer-based reminders by km left', () => {
    const r = reminder({ dueOdometerKm: 50_000 });
    expect(reminderStatus(r, 50_100, today)).toMatchObject({ urgency: 'overdue', kmLeft: -100 });
    expect(reminderStatus(r, 49_700, today).urgency).toBe('due_soon');
    expect(reminderStatus(r, 49_000, today).urgency).toBe('upcoming');
    expect(reminderStatus(r, 40_000, today).urgency).toBe('later');
  });

  it('uses whichever target is closer when both are set', () => {
    const r = reminder({ dueDate: new Date('2027-03-01'), dueOdometerKm: 50_000 });
    expect(reminderStatus(r, 49_900, today).urgency).toBe('due_soon');
  });

  it('reports completed reminders as done regardless of targets', () => {
    const r = reminder({ dueDate: new Date('2020-01-01'), completedAt: new Date() });
    expect(reminderStatus(r, 0, today).urgency).toBe('done');
  });
});

describe('nextOccurrence', () => {
  it('returns null for one-off reminders', () => {
    expect(nextOccurrence(reminder({ dueDate: today }), 0, today)).toBeNull();
  });

  it('counts from completion, not from the old due point', () => {
    const r = reminder({ dueDate: new Date('2026-06-01'), dueOdometerKm: 40_000, repeatMonths: 6, repeatKm: 10_000 });
    expect(nextOccurrence(r, 41_200, today)).toEqual({
      dueDate: new Date('2027-03-23T00:00:00.000Z'),
      dueOdometerKm: 51_200,
    });
  });
});

describe('addMonths', () => {
  it('clamps to the end of shorter months', () => {
    expect(addMonths(new Date('2026-01-31T00:00:00.000Z'), 1).toISOString().slice(0, 10)).toBe('2026-02-28');
  });
});

describe('todayInUae', () => {
  it('uses the Dubai calendar date, which is ahead of UTC late in the evening', () => {
    expect(todayInUae(new Date('2026-09-23T21:30:00.000Z')).toISOString()).toBe('2026-09-24T00:00:00.000Z');
  });
});
