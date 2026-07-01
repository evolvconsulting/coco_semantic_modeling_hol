import type { Exceptions } from "../../../api";
import { MetricSection } from "../MetricSection/MetricSection";
import { Stat } from "../Stat/Stat";
import { peerDeviation, percent } from "../shared/format";

interface ExceptionsSectionProps {
  data: Exceptions;
  index?: number;
  active?: boolean;
  onHover?: (target: HTMLElement | null) => void;
}

export function ExceptionsSection({
  data,
  index,
  active,
  onHover,
}: ExceptionsSectionProps) {
  return (
    <MetricSection
      label="Exceptions"
      index={index}
      active={active}
      onHover={onHover}
      why={data.why}
      stats={
        <>
          <Stat
            label="Exception Rate"
            value={percent(data.dealer_rate)}
            sub={`peer ${percent(data.peer_rate)}`}
            peerDeviation={peerDeviation(data.dealer_rate, data.peer_rate, false)}
          />
          {data.types.map((type) => (
            <Stat
              key={type.exception_type}
              label={type.label}
              value={percent(type.share)}
              sub={`${type.count} held`}
            />
          ))}
        </>
      }
    />
  );
}
