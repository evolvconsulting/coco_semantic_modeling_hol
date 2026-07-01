import type { CSSProperties } from "react";
import "./Kpi.css";

export type KpiFormat = "percent" | "days";

interface KpiProps {
  label: string;
  value: number;
  prior: number;
  format: KpiFormat;
  higherIsBetter: boolean;
}

export function Kpi({ label, value, prior, format, higherIsBetter }: KpiProps) {
  const text = formatValue(value, format);
  const delta = prior === 0 ? 0 : (value - prior) / Math.abs(prior);

  return (
    <div className="tooltip-kpi">
      <span className="tooltip-kpi-label">{label}</span>
      <span className="tooltip-kpi-readout">
        <span className="tooltip-kpi-value">
          <Reels text={text} />
        </span>
        <Trend delta={delta} higherIsBetter={higherIsBetter} />
      </span>
    </div>
  );
}

const TREND_EPSILON = 0.005;

function Trend({
  delta,
  higherIsBetter,
}: {
  delta: number;
  higherIsBetter: boolean;
}) {
  if (Math.abs(delta) < TREND_EPSILON) {
    return <span className="tooltip-kpi-trend tooltip-kpi-trend-flat">—</span>;
  }

  const rising = delta > 0;
  const good = rising === higherIsBetter;
  const arrow = rising ? "▲" : "▼";
  const pct = `${Math.abs(delta * 100).toFixed(0)}%`;

  return (
    <span
      className={`tooltip-kpi-trend ${good ? "is-good" : "is-bad"}`}
    >
      {arrow} {pct}
    </span>
  );
}

const DIGITS = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
const REEL_STEP = 0.06;

function Reels({ text }: { text: string }) {
  let digitIndex = 0;

  return (
    <span className="reels" aria-label={text}>
      {Array.from(text).map((char, i) => {
        if (!isDigit(char)) {
          return (
            <span key={i} className="reel-static" aria-hidden>
              {char}
            </span>
          );
        }
        const delay = digitIndex * REEL_STEP;
        digitIndex += 1;
        return <Reel key={i} digit={Number(char)} delay={delay} />;
      })}
    </span>
  );
}

function Reel({ digit, delay }: { digit: number; delay: number }) {
  const style = {
    "--reel-target": `${-digit}em`,
    "--reel-delay": `${delay}s`,
  } as CSSProperties;

  return (
    <span className="reel" aria-hidden>
      <span className="reel-strip" style={style}>
        {DIGITS.map((d) => (
          <span key={d} className="reel-cell">
            {d}
          </span>
        ))}
      </span>
    </span>
  );
}

function isDigit(char: string): boolean {
  return char >= "0" && char <= "9";
}

function formatValue(value: number, format: KpiFormat): string {
  switch (format) {
    case "percent":
      return `${(value * 100).toFixed(1)}%`;
    case "days":
      return `${value.toFixed(1)}d`;
  }
}
