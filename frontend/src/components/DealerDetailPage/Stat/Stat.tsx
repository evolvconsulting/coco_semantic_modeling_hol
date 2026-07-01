import type { CSSProperties, ReactNode } from "react";
import "./Stat.css";

interface StatProps {
  label: string;
  value: string;
  sub?: string;
  delta?: ReactNode;
  peerDeviation?: number;
}

const DEVIATION_CAP = 0.5;

export function Stat({ label, value, sub, delta, peerDeviation }: StatProps) {
  const intensity =
    peerDeviation === undefined
      ? 0
      : Math.min(Math.abs(peerDeviation), DEVIATION_CAP) / DEVIATION_CAP;
  const tone =
    peerDeviation === undefined || peerDeviation === 0
      ? undefined
      : peerDeviation > 0
        ? "is-ahead"
        : "is-behind";
  const style = { "--peer-intensity": intensity } as CSSProperties;

  return (
    <div className="stat">
      <div className="stat-label">{label}</div>
      <div className="stat-value-row">
        <span
          className={`stat-value${tone ? ` ${tone}` : ""}`}
          style={tone ? style : undefined}
        >
          {value}
        </span>
        {delta}
      </div>
      {sub && <div className="stat-sub">{sub}</div>}
    </div>
  );
}
