export const DELTA_EPSILON = 1e-9;

export function percent(value: number, digits = 0): string {
  return `${(value * 100).toFixed(digits)}%`;
}

export function days(value: number, digits = 1): string {
  return `${value.toFixed(digits)}d`;
}

export function points(delta: number): string {
  const sign = delta > 0 ? "+" : "";
  return `${sign}${(delta * 100).toFixed(0)}pt`;
}

export function pointsMagnitude(value: number): string {
  return `${(value * 100).toFixed(0)} pt`;
}

export function daysMagnitude(value: number): string {
  return `${value.toFixed(1)} d`;
}

export function peerDeviation(
  value: number,
  peer: number,
  higherIsBetter: boolean,
): number {
  if (peer === 0) return 0;
  const ratio = (value - peer) / Math.abs(peer);
  return higherIsBetter ? ratio : -ratio;
}
