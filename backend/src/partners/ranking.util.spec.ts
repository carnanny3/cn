import { rankPartners } from './ranking.util';

describe('rankPartners', () => {
  it('ranks a closer, higher-rated, cheaper partner above a farther, lower-rated, pricier one', () => {
    const results = rankPartners(
      [
        { id: 'far', ratingAvg: 3.5, cancellationRate: 0.1, price: 300, latitude: 25.3, longitude: 55.5 },
        { id: 'near', ratingAvg: 4.9, cancellationRate: 0.01, price: 150, latitude: 25.2, longitude: 55.27 },
      ],
      25.2048,
      55.2708,
      300,
    );

    expect(results[0].id).toBe('near');
    expect(results[0].score).toBeGreaterThan(results[1].score);
  });

  it('falls back to a neutral distance score when coordinates are unavailable', () => {
    const results = rankPartners(
      [{ id: 'p1', ratingAvg: 4.5, cancellationRate: 0.05, price: 100, latitude: null, longitude: null }],
      null,
      null,
      100,
    );

    expect(results[0].distanceKm).toBeNull();
    expect(results[0].score).toBeGreaterThan(0);
  });

  it('never produces a negative score component from distance beyond the falloff radius', () => {
    const results = rankPartners(
      [{ id: 'far', ratingAvg: 5, cancellationRate: 0, price: 100, latitude: 30, longitude: 60 }],
      25.2048,
      55.2708,
      100,
    );

    expect(results[0].score).toBeGreaterThanOrEqual(0);
  });
});
