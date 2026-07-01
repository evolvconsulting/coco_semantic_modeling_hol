import type { Dealer, MonthlyMetrics } from "./api";

export type Health = "green" | "yellow" | "red";

export const HEALTH_LABELS: Record<Health, string> = {
  green: "Healthy",
  yellow: "At Risk",
  red: "Critical",
};

const RED_DECLINES = 2;
const YELLOW_DECLINES = 1;

const LOOK_TO_BOOK_DROP = 0.08;
const FUNDING_VELOCITY_RISE = 1.0;
const EXCEPTION_RATE_RISE = 0.08;

export function healthOf(dealer: Dealer): Health {
  const first = dealer.performance[0];
  const last = dealer.performance[dealer.performance.length - 1];

  if (!first || !last) return "green";

  const declines = countDeclines(first, last);

  if (declines >= RED_DECLINES) return "red";
  if (declines >= YELLOW_DECLINES) return "yellow";
  return "green";
}

function countDeclines(first: MonthlyMetrics, last: MonthlyMetrics): number {
  const signals = [
    first.look_to_book - last.look_to_book >= LOOK_TO_BOOK_DROP,
    last.funding_velocity - first.funding_velocity >= FUNDING_VELOCITY_RISE,
    last.exception_rate - first.exception_rate >= EXCEPTION_RATE_RISE,
  ];
  return signals.filter(Boolean).length;
}

const GOOD_LOOK_TO_BOOK = 0.55;
const SLOW_FUNDING_VELOCITY = 6.0;
const HIGH_EXCEPTION_RATE = 0.35;

export function scoreOf(month: MonthlyMetrics): number {
  const parts = [
    clamp(month.look_to_book / GOOD_LOOK_TO_BOOK),
    clamp(1 - month.funding_velocity / SLOW_FUNDING_VELOCITY),
    clamp(1 - month.exception_rate / HIGH_EXCEPTION_RATE),
  ];
  return parts.reduce((sum, part) => sum + part, 0) / parts.length;
}

function clamp(value: number): number {
  return Math.max(0, Math.min(1, value));
}
