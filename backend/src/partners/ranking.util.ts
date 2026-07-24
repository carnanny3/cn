export interface RankablePartner {
  id: string;
  ratingAvg: number;
  cancellationRate: number;
  price: number;
  latitude: number | null;
  longitude: number | null;
}

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) * Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.asin(Math.sqrt(a));
}

/**
 * Partner ranking per the product spec (Section 9): distance, rating, price,
 * and cancellation rate combine into a single score. Weights are tunable —
 * this is a transparent, explainable starting formula, not a black box.
 */
export function rankPartners(
  partners: RankablePartner[],
  customerLat: number | null,
  customerLng: number | null,
  maxPrice: number,
): Array<RankablePartner & { score: number; distanceKm: number | null }> {
  return partners
    .map((p) => {
      const distanceKm =
        customerLat !== null && customerLng !== null && p.latitude !== null && p.longitude !== null
          ? haversineKm(customerLat, customerLng, p.latitude, p.longitude)
          : null;

      const distanceScore = distanceKm === null ? 0.5 : Math.max(0, 1 - distanceKm / 25);
      const ratingScore = p.ratingAvg / 5;
      const priceScore = maxPrice > 0 ? 1 - p.price / maxPrice : 0.5;
      const reliabilityScore = Math.max(0, 1 - p.cancellationRate);

      const score =
        distanceScore * 0.35 + ratingScore * 0.3 + priceScore * 0.2 + reliabilityScore * 0.15;

      return { ...p, score: Math.round(score * 1000) / 1000, distanceKm };
    })
    .sort((a, b) => b.score - a.score);
}
