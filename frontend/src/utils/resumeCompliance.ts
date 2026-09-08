// Mirrors core.AppSettings: Resume.ComplianceDays (30) and Resume.OverdueDays (45).
// A background job recalculates this monthly server-side; this is the same logic
// applied client-side for display purposes only.

export type ResumeComplianceState = "Compliant" | "Due soon" | "Overdue";

const COMPLIANCE_DAYS = 30;
const OVERDUE_DAYS = 45;

// Fixed reference "today" so the mock behaves deterministically in a demo.
// In the real app this is simply `new Date()`.
export const MOCK_TODAY = new Date("2026-09-02T00:00:00");

export function daysSince(dateISO: string, today: Date = MOCK_TODAY): number {
  const then = new Date(dateISO);
  const msPerDay = 1000 * 60 * 60 * 24;
  return Math.floor((today.getTime() - then.getTime()) / msPerDay);
}

export function getResumeComplianceState(
  lastUpdatedISO: string,
  today: Date = MOCK_TODAY
): { state: ResumeComplianceState; daysSince: number } {
  const elapsed = daysSince(lastUpdatedISO, today);
  if (elapsed < COMPLIANCE_DAYS) return { state: "Compliant", daysSince: elapsed };
  if (elapsed < OVERDUE_DAYS) return { state: "Due soon", daysSince: elapsed };
  return { state: "Overdue", daysSince: elapsed };
}

export function formatDate(dateISO: string): string {
  return new Date(dateISO).toLocaleDateString("en-IN", {
    day: "numeric",
    month: "short",
    year: "numeric",
  });
}
