import { calculateFuelEconomy, FuelFill } from './fuel-economy.util';

let seq = 0;
function fill(odometerKm: number, liters: number, overrides: Partial<FuelFill> = {}): FuelFill {
  seq += 1;
  return {
    id: `f${seq}`,
    date: new Date(Date.UTC(2026, 0, seq)),
    odometerKm,
    liters,
    cost: liters * 3,
    fullTank: true,
    missedPrevious: false,
    ...overrides,
  };
}

describe('calculateFuelEconomy', () => {
  it('has nothing to measure from a single fill-up', () => {
    const result = calculateFuelEconomy([fill(10_000, 50)]);
    expect(result.fills[0].kmPerLiter).toBeNull();
    expect(result.averageKmPerLiter).toBeNull();
  });

  it('measures between two full tanks using the second fill', () => {
    const result = calculateFuelEconomy([fill(10_000, 50), fill(10_600, 50)]);
    expect(result.fills[0].kmPerLiter).toBeCloseTo(12);
    expect(result.fills[0].litersPer100Km).toBeCloseTo(8.333, 2);
    expect(result.fills[0].distanceKm).toBe(600);
  });

  it('adds partial top-ups into the next full tank', () => {
    const result = calculateFuelEconomy([
      fill(10_000, 50),
      fill(10_300, 20, { fullTank: false }),
      fill(10_700, 30),
    ]);
    const [latest, partial] = result.fills;
    expect(partial.kmPerLiter).toBeNull();
    expect(latest.kmPerLiter).toBeCloseTo(700 / 50);
  });

  it('restarts the chain after a missed fill-up', () => {
    const result = calculateFuelEconomy([
      fill(10_000, 50),
      fill(11_500, 45, { missedPrevious: true }),
      fill(12_000, 40),
    ]);
    const [latest, missed] = result.fills;
    expect(missed.kmPerLiter).toBeNull();
    expect(latest.kmPerLiter).toBeCloseTo(500 / 40);
  });

  it('weights the average by distance rather than averaging the averages', () => {
    const result = calculateFuelEconomy([fill(0, 10), fill(100, 10), fill(1_100, 50)]);
    // Segments: 100 km on 10 L and 1000 km on 50 L -> 1100 km / 60 L.
    expect(result.averageKmPerLiter).toBeCloseTo(1100 / 60);
  });

  it('sorts by odometer regardless of input order and returns newest first', () => {
    const a = fill(20_000, 40);
    const b = fill(20_500, 40);
    const result = calculateFuelEconomy([b, a]);
    expect(result.fills.map((f) => f.entry.id)).toEqual([b.id, a.id]);
    expect(result.fills[0].kmPerLiter).toBeCloseTo(12.5);
  });
});
