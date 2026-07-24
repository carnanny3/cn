export const AI_DISCLAIMER =
  'This is AI-generated guidance and not a substitute for professional mechanical, legal, or financial advice.';

const UNSAFE_TO_DRIVE_PATTERNS = [/safe to drive/i, /can i drive/i, /is it safe/i];

/**
 * Deterministic, non-LLM-controlled safety layer (per the product's AI
 * safety rules): appends the disclaimer to any response and hard-redirects
 * "is this safe to drive" questions to a professional rather than letting
 * the responder assert safety directly, regardless of how confident its
 * underlying data looks.
 */
export function applySafetyRules(userMessage: string, draftResponse: string, hasCriticalDefect: boolean): string {
  const asksAboutSafety = UNSAFE_TO_DRIVE_PATTERNS.some((p) => p.test(userMessage));

  if (asksAboutSafety && hasCriticalDefect) {
    return `I can't confirm this vehicle is safe to drive — the latest inspection found a critical defect. Please have it looked at by a qualified mechanic before driving it further. ${AI_DISCLAIMER}`;
  }

  return `${draftResponse}\n\n${AI_DISCLAIMER}`;
}
