export interface FuelFill {
  id: string;
  date: Date;
  odometerKm: number;
  liters: number;
  cost: number;
  fullTank: boolean;
  missedPrevious: boolean;
}

export interface FuelFillWithEconomy<T extends FuelFill = FuelFill> {
  entry: T;
  /** Kilometres since the previous logged fill-up, whatever its tank state. */
  distanceKm: number | null;
  /** Measured between this full tank and the previous full tank; null when not measurable. */
  kmPerLiter: number | null;
  litersPer100Km: number | null;
  pricePerLiter: number | null;
}

export interface FuelEconomySummary<T extends FuelFill = FuelFill> {
  /** Newest first, the order the app lists them in. */
  fills: FuelFillWithEconomy<T>[];
  /** Distance-weighted across every measurable segment, not an average of averages. */
  averageKmPerLiter: number | null;
  averageLitersPer100Km: number | null;
  totalLiters: number;
  totalCost: number;
}

/**
 * Fuel economy from a vehicle's fill-ups.
 *
 * Economy is only knowable between two full tanks: the fuel put in at the second
 * one (plus any partial top-ups in between) is exactly what was burned over that
 * distance. A fill-up flagged `missedPrevious` means fuel went in that was never
 * logged, so the segment ending there is unknowable and the chain restarts.
 */
export function calculateFuelEconomy<T extends FuelFill>(entries: T[]): FuelEconomySummary<T> {
  const ascending = [...entries].sort(
    (a, b) => a.odometerKm - b.odometerKm || a.date.getTime() - b.date.getTime() || a.id.localeCompare(b.id),
  );

  const fills: FuelFillWithEconomy<T>[] = [];
  let previousOdometer: number | null = null;
  let lastFullOdometer: number | null = null;
  let litersSinceLastFull = 0;
  let measuredKm = 0;
  let measuredLiters = 0;

  for (const entry of ascending) {
    if (entry.missedPrevious) {
      lastFullOdometer = null;
      litersSinceLastFull = 0;
    }
    litersSinceLastFull += entry.liters;

    let kmPerLiter: number | null = null;
    if (entry.fullTank) {
      if (lastFullOdometer !== null && entry.odometerKm > lastFullOdometer && litersSinceLastFull > 0) {
        const km = entry.odometerKm - lastFullOdometer;
        kmPerLiter = km / litersSinceLastFull;
        measuredKm += km;
        measuredLiters += litersSinceLastFull;
      }
      lastFullOdometer = entry.odometerKm;
      litersSinceLastFull = 0;
    }

    fills.push({
      entry,
      distanceKm: previousOdometer === null ? null : entry.odometerKm - previousOdometer,
      kmPerLiter,
      litersPer100Km: kmPerLiter ? 100 / kmPerLiter : null,
      pricePerLiter: entry.liters > 0 ? entry.cost / entry.liters : null,
    });
    previousOdometer = entry.odometerKm;
  }

  const averageKmPerLiter = measuredLiters > 0 ? measuredKm / measuredLiters : null;
  return {
    fills: fills.reverse(),
    averageKmPerLiter,
    averageLitersPer100Km: averageKmPerLiter ? 100 / averageKmPerLiter : null,
    totalLiters: entries.reduce((sum, e) => sum + e.liters, 0),
    totalCost: entries.reduce((sum, e) => sum + e.cost, 0),
  };
}
