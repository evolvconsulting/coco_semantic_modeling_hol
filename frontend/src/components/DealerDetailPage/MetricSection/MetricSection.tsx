import type { CSSProperties, ReactNode } from "react";
import { StatRow } from "../StatRow/StatRow";
import { WhyBlock } from "../WhyBlock/WhyBlock";
import "./MetricSection.css";

interface MetricSectionProps {
  label: string;
  stats: ReactNode;
  why: string;
  index?: number;
  active?: boolean;
  onHover?: (target: HTMLElement | null) => void;
}

export function MetricSection({
  label,
  stats,
  why,
  index = 0,
  active = false,
  onHover,
}: MetricSectionProps) {
  const style = { "--cascade-delay": `${index * 0.09}s` } as CSSProperties;

  return (
    <section
      className="metric-section"
      style={style}
      onMouseEnter={(e) => onHover?.(e.currentTarget)}
      onMouseLeave={() => onHover?.(null)}
    >
      <div className={`metric-section-content${active ? " is-active" : ""}`}>
        <h2 className="metric-section-label">{label}</h2>
        <StatRow>{stats}</StatRow>
        <WhyBlock>{why}</WhyBlock>
      </div>
    </section>
  );
}
