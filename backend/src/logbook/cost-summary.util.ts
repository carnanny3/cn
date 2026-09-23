export const COST_CATEGORIES = ['service', 'repair', 'upgrade', 'fee', 'fuel', 'car_nanny'] as const;
export type CostCategory = (typeof COST_CATEGORIES)[number];

export interface CostItem {
  category: CostCategory;
  date: Date;
  amount: number;
}

export type CategoryTotals = Record<CostCategory, number>;

export interface MonthlyCosts extends CategoryTotals {
  /** YYYY-MM */
  month: string;
}

export interface CostSummary {
  totals: CategoryTotals;
  total: number;
  /** Trailing 12 calendar months ending with the current one, oldest first. */
  monthly: MonthlyCosts[];
}

const emptyTotals = (): CategoryTotals =>
  Object.fromEntries(COST_CATEGORIES.map((c) => [c, 0])) as CategoryTotals;

const monthKey = (d: Date) => d.toISOString().slice(0, 7);

/**
 * All-time totals by category plus a trailing-12-month breakdown. `car_nanny`
 * is money spent on completed Car Nanny bookings, kept separate so owners can
 * see it without it being double-counted against their own service entries.
 */
export function summarizeCosts(items: CostItem[], today: Date): CostSummary {
  const totals = emptyTotals();
  const monthly: MonthlyCosts[] = [];
  for (let i = 11; i >= 0; i--) {
    const d = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth() - i, 1));
    monthly.push({ month: monthKey(d), ...emptyTotals() });
  }
  const byMonth = new Map(monthly.map((m) => [m.month, m]));

  for (const item of items) {
    totals[item.category] += item.amount;
    const bucket = byMonth.get(monthKey(item.date));
    if (bucket) bucket[item.category] += item.amount;
  }

  return {
    totals,
    total: Object.values(totals).reduce((a, b) => a + b, 0),
    monthly,
  };
}
