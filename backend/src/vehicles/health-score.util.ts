export interface HealthScoreInputs {
  latestInspectionScoreOutOf10: number | null;
  completedServiceBookingsLast12Months: number;
  vehicleYear: number;
  requiredDocsPresentAndValid: number;
  requiredDocsTotal: number;
}

export interface HealthScoreBreakdown {
  overall: number;
  categories: {
    inspection: number;
    maintenance: number;
    documents: number;
    ageMileage: number;
  };
  recommendations: string[];
}

/**
 * Deterministic, explainable Vehicle Health Score (0-100) per the product
 * spec: weighted blend of inspection findings, maintenance frequency,
 * document validity, and vehicle age. No inspection yet -> lower confidence
 * default rather than a fabricated high score.
 */
export function calculateHealthScore(inputs: HealthScoreInputs): HealthScoreBreakdown {
  const currentYear = new Date().getFullYear();
  const age = Math.max(0, currentYear - inputs.vehicleYear);

  const inspectionScore =
    inputs.latestInspectionScoreOutOf10 === null
      ? 65
      : Math.round(inputs.latestInspectionScoreOutOf10 * 10);

  const maintenanceScore = Math.min(
    100,
    50 + inputs.completedServiceBookingsLast12Months * 12,
  );

  const documentsScore =
    inputs.requiredDocsTotal === 0
      ? 50
      : Math.round((inputs.requiredDocsPresentAndValid / inputs.requiredDocsTotal) * 100);

  const ageMileageScore = Math.max(20, 100 - age * 6);

  const overall = Math.round(
    inspectionScore * 0.4 +
      maintenanceScore * 0.25 +
      documentsScore * 0.2 +
      ageMileageScore * 0.15,
  );

  const recommendations: string[] = [];
  if (inputs.latestInspectionScoreOutOf10 === null) {
    recommendations.push('Book an inspection to get an accurate health score based on this vehicle\'s actual condition.');
  }
  if (documentsScore < 100) {
    recommendations.push('One or more required documents are missing or expired — update them in Documents to avoid registration or insurance lapses.');
  }
  if (inputs.completedServiceBookingsLast12Months === 0) {
    recommendations.push('No service history in the last 12 months — book a routine service to keep this vehicle in good condition.');
  }

  return {
    overall: Math.max(0, Math.min(100, overall)),
    categories: {
      inspection: inspectionScore,
      maintenance: maintenanceScore,
      documents: documentsScore,
      ageMileage: ageMileageScore,
    },
    recommendations,
  };
}
