import { TfiAngleDoubleDown, TfiAngleDoubleUp } from "react-icons/tfi";
import { DELTA_EPSILON } from "./format";
import "./deltaRipple.css";
import "./DeltaIndicator.css";

interface DeltaIndicatorProps {
  delta: number;
  higherIsBetter: boolean;
  format: (value: number) => string;
  size?: "sm" | "lg";
  epsilon?: number;
}

export function DeltaIndicator({
  delta,
  higherIsBetter,
  format,
  size = "sm",
  epsilon = DELTA_EPSILON,
}: DeltaIndicatorProps) {
  const base = `delta-indicator delta-indicator--${size}`;

  if (Math.abs(delta) < epsilon) {
    return <span className={`${base} delta-indicator--flat`}>—</span>;
  }

  const rising = delta > 0;
  const good = rising === higherIsBetter;
  const Arrow = rising ? TfiAngleDoubleUp : TfiAngleDoubleDown;
  const tone = good ? "is-good" : "is-bad";
  const dir = rising ? "delta-indicator--up" : "delta-indicator--down";

  return (
    <span className={`${base} ${tone} ${dir}`}>
      <Arrow className="delta-indicator-icon" aria-hidden />
      <span className="delta-indicator-text">{format(Math.abs(delta))}</span>
    </span>
  );
}
