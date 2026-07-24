import { calculateHealthScore } from './health-score.util';

describe('calculateHealthScore', () => {
  it('gives a lower-confidence default when no inspection exists yet', () => {
    const result = calculateHealthScore({
      latestInspectionScoreOutOf10: null,
      completedServiceBookingsLast12Months: 0,
      vehicleYear: new Date().getFullYear(),
      requiredDocsPresentAndValid: 0,
      requiredDocsTotal: 2,
    });

    expect(result.categories.inspection).toBe(65);
    expect(result.recommendations).toContain(
      'Book an inspection to get an accurate health score based on this vehicle\'s actual condition.',
    );
  });

  it('scores higher for a well-documented, recently-inspected, well-maintained vehicle', () => {
    const result = calculateHealthScore({
      latestInspectionScoreOutOf10: 9.5,
      completedServiceBookingsLast12Months: 3,
      vehicleYear: new Date().getFullYear(),
      requiredDocsPresentAndValid: 2,
      requiredDocsTotal: 2,
    });

    expect(result.overall).toBeGreaterThan(85);
    expect(result.recommendations).toHaveLength(0);
  });

  it('penalizes older vehicles via the age/mileage category', () => {
    const currentYear = new Date().getFullYear();
    const newer = calculateHealthScore({
      latestInspectionScoreOutOf10: 8,
      completedServiceBookingsLast12Months: 1,
      vehicleYear: currentYear,
      requiredDocsPresentAndValid: 2,
      requiredDocsTotal: 2,
    });
    const older = calculateHealthScore({
      latestInspectionScoreOutOf10: 8,
      completedServiceBookingsLast12Months: 1,
      vehicleYear: currentYear - 15,
      requiredDocsPresentAndValid: 2,
      requiredDocsTotal: 2,
    });

    expect(older.categories.ageMileage).toBeLessThan(newer.categories.ageMileage);
    expect(older.overall).toBeLessThan(newer.overall);
  });

  it('flags missing/expired documents with a recommendation', () => {
    const result = calculateHealthScore({
      latestInspectionScoreOutOf10: 8,
      completedServiceBookingsLast12Months: 1,
      vehicleYear: new Date().getFullYear(),
      requiredDocsPresentAndValid: 1,
      requiredDocsTotal: 2,
    });

    expect(result.categories.documents).toBe(50);
    expect(result.recommendations.some((r) => r.includes('document'))).toBe(true);
  });

  it('clamps the overall score to the 0-100 range', () => {
    const result = calculateHealthScore({
      latestInspectionScoreOutOf10: 0,
      completedServiceBookingsLast12Months: 0,
      vehicleYear: new Date().getFullYear() - 40,
      requiredDocsPresentAndValid: 0,
      requiredDocsTotal: 2,
    });

    expect(result.overall).toBeGreaterThanOrEqual(0);
    expect(result.overall).toBeLessThanOrEqual(100);
  });
});
