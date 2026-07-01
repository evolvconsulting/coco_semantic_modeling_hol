import type { Funding } from "../../../api";
import { MetricSection } from "../MetricSection/MetricSection";
import { Stat } from "../Stat/Stat";
import { StatDelta } from "../StatDelta/StatDelta";
import {
  days,
  daysMagnitude,
  peerDeviation,
  percent,
  pointsMagnitude,
} from "../shared/format";

interface FundingSectionProps {
  data: Funding;
  index?: number;
  active?: boolean;
  onHover?: (target: HTMLElement | null) => void;
}

export function FundingSection({
  data,
  index,
  active,
  onHover,
}: FundingSectionProps) {
  const first = data.months[0];
  const latest = data.months[data.months.length - 1];

  return (
    <MetricSection
      label="Funding"
      index={index}
      active={active}
      onHover={onHover}
      why={data.why}
      stats={
        <>
          <Stat
            label="Avg Funding Time"
            value={days(latest.avg_funding_days)}
            sub={`peer ${days(data.peer_avg_days)}`}
            peerDeviation={peerDeviation(
              latest.avg_funding_days,
              data.peer_avg_days,
              false,
            )}
            delta={
              <StatDelta
                delta={latest.avg_funding_days - first.avg_funding_days}
                higherIsBetter={false}
                format={daysMagnitude}
              />
            }
          />
          <Stat
            label="Funded > 5 Days"
            value={percent(latest.slow_share)}
            delta={
              <StatDelta
                delta={latest.slow_share - first.slow_share}
                higherIsBetter={false}
                format={pointsMagnitude}
              />
            }
          />
          <Stat label="Contracts" value={`${latest.contracts}`} />
        </>
      }
    />
  );
}
