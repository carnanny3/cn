import { summarizeCosts } from './cost-summary.util';

const today = new Date('2026-09-23T00:00:00.000Z');

describe('summarizeCosts', () => {
  it('returns twelve months ending with the current one, oldest first', () => {
    const { monthly } = summarizeCosts([], today);
    expect(monthly).toHaveLength(12);
    expect(monthly[0].month).toBe('2025-10');
    expect(monthly[11].month).toBe('2026-09');
  });

  it('totals by category and buckets recent items by month', () => {
    const result = summarizeCosts(
      [
        { category: 'service', date: new Date('2026-09-02'), amount: 300 },
        { category: 'fuel', date: new Date('2026-09-10'), amount: 120 },
        { category: 'fuel', date: new Date('2026-08-10'), amount: 100 },
        { category: 'repair', date: new Date('2024-01-01'), amount: 900 },
      ],
      today,
    );
    expect(result.totals).toMatchObject({ service: 300, fuel: 220, repair: 900 });
    expect(result.total).toBe(1420);
    expect(result.monthly[11]).toMatchObject({ service: 300, fuel: 120 });
    expect(result.monthly[10]).toMatchObject({ fuel: 100 });
    // Older than 12 months: counted in totals, absent from the chart.
    expect(result.monthly.reduce((s, m) => s + m.repair, 0)).toBe(0);
  });
});
