export interface CheckpointInput {
  category: string;
  checkpointName: string;
  result: 'pass' | 'minor_defect' | 'critical_defect' | 'not_applicable';
}

export interface GeneratedReport {
  overallScore: number;
  overallStatus: 'green' | 'amber' | 'red';
  categoryScores: Record<string, number>;
  criticalDefectCount: number;
  minorDefectCount: number;
  estimatedRepairCost: number;
  aiSummary: string;
  aiRecommendation: 'buy' | 'buy_after_negotiation' | 'proceed_with_caution' | 'do_not_buy';
}

const RESULT_POINTS: Record<string, number> = {
  pass: 10,
  minor_defect: 6,
  critical_defect: 0,
  not_applicable: -1, // excluded from scoring
};

const CRITICAL_DEFECT_COST_AED = 1500;
const MINOR_DEFECT_COST_AED = 300;

/**
 * Deterministic, explainable report generator standing in for the AI
 * analysis described in the product spec. It is a legitimate rule-based
 * "AI" implementation today; swap `summarize()` for a real LLM call (with
 * the same RAG-over-checkpoints contract) without changing callers —
 * scores/recommendation stay deterministic either way per the product's
 * AI safety rules (fixed recommendation enum, mandatory disclaimer).
 */
export function generateInspectionReport(
  checkpoints: CheckpointInput[],
  vehicleLabel: string,
): GeneratedReport {
  const byCategory = new Map<string, CheckpointInput[]>();
  for (const cp of checkpoints) {
    const list = byCategory.get(cp.category) ?? [];
    list.push(cp);
    byCategory.set(cp.category, list);
  }

  const categoryScores: Record<string, number> = {};
  for (const [category, cps] of byCategory) {
    const scored = cps.filter((c) => c.result !== 'not_applicable');
    if (scored.length === 0) continue;
    const avg = scored.reduce((sum, c) => sum + RESULT_POINTS[c.result], 0) / scored.length;
    categoryScores[category] = Math.round(avg * 10) / 10;
  }

  const scoreValues = Object.values(categoryScores);
  const overallScore =
    scoreValues.length === 0
      ? 0
      : Math.round((scoreValues.reduce((a, b) => a + b, 0) / scoreValues.length) * 10) / 10;

  const criticalDefectCount = checkpoints.filter((c) => c.result === 'critical_defect').length;
  const minorDefectCount = checkpoints.filter((c) => c.result === 'minor_defect').length;

  const estimatedRepairCost =
    criticalDefectCount * CRITICAL_DEFECT_COST_AED + minorDefectCount * MINOR_DEFECT_COST_AED;

  let overallStatus: 'green' | 'amber' | 'red';
  if (criticalDefectCount > 0 || overallScore < 6) {
    overallStatus = 'red';
  } else if (overallScore < 8 || minorDefectCount >= 3) {
    overallStatus = 'amber';
  } else {
    overallStatus = 'green';
  }

  let aiRecommendation: GeneratedReport['aiRecommendation'];
  if (criticalDefectCount >= 2 || overallScore < 5) {
    aiRecommendation = 'do_not_buy';
  } else if (criticalDefectCount === 1 || overallScore < 6.5) {
    aiRecommendation = 'proceed_with_caution';
  } else if (minorDefectCount >= 3 || overallScore < 8.5) {
    aiRecommendation = 'buy_after_negotiation';
  } else {
    aiRecommendation = 'buy';
  }

  const worstCategories = Object.entries(categoryScores)
    .sort((a, b) => a[1] - b[1])
    .slice(0, 3)
    .filter(([, score]) => score < 8)
    .map(([category]) => category);

  const aiSummary =
    worstCategories.length > 0
      ? `${vehicleLabel} scored ${overallScore}/10 overall. The areas needing the most attention are: ${worstCategories.join(', ')}. ${criticalDefectCount > 0 ? `${criticalDefectCount} critical defect(s) were found and should be resolved before purchase or immediately after.` : `${minorDefectCount} minor defect(s) were found — factor an estimated AED ${estimatedRepairCost} into any negotiation.`}`
      : `${vehicleLabel} scored ${overallScore}/10 overall with no significant issues found across inspected categories.`;

  return {
    overallScore,
    overallStatus,
    categoryScores,
    criticalDefectCount,
    minorDefectCount,
    estimatedRepairCost,
    aiSummary,
    aiRecommendation,
  };
}

export const AI_DISCLAIMER =
  'This is AI-generated guidance based on inspection data and is not a substitute for professional mechanical, legal, or financial advice.';
