import type { CreditMix } from "../../../api";
import { MetricSection } from "../MetricSection/MetricSection";
import { Stat } from "../Stat/Stat";
import { StatDelta } from "../StatDelta/StatDelta";
import { peerDeviation, percent, pointsMagnitude } from "../shared/format";

interface CreditMixSectionProps {
  data: CreditMix;
  index?: number;
  active?: boolean;
  onHover?: (target: HTMLElement | null) => void;
}

export function CreditMixSection({
  data,
  index,
  active,
  onHover,
}: CreditMixSectionProps) {
  const first = data.months[0];
  const latest = data.months[data.months.length - 1];

  return (
    <MetricSection
      label="Credit Mix"
      index={index}
      active={active}
      onHover={onHover}
      why={data.why}
      stats={
        <>
          <Stat
            label="Prime"
            value={percent(latest.prime)}
            sub={`peer ${percent(data.peer.prime)}`}
            peerDeviation={peerDeviation(latest.prime, data.peer.prime, true)}
            delta={
              <StatDelta
                delta={latest.prime - first.prime}
                higherIsBetter
                format={pointsMagnitude}
              />
            }
          />
          <Stat
            label="Near-Prime"
            value={percent(latest.near_prime)}
            sub={`peer ${percent(data.peer.near_prime)}`}
            peerDeviation={peerDeviation(
              latest.near_prime,
              data.peer.near_prime,
              false,
            )}
            delta={
              <StatDelta
                delta={latest.near_prime - first.near_prime}
                higherIsBetter={false}
                format={pointsMagnitude}
              />
            }
          />
          <Stat
            label="Subprime"
            value={percent(latest.subprime)}
            sub={`peer ${percent(data.peer.subprime)}`}
            peerDeviation={peerDeviation(
              latest.subprime,
              data.peer.subprime,
              false,
            )}
            delta={
              <StatDelta
                delta={latest.subprime - first.subprime}
                higherIsBetter={false}
                format={pointsMagnitude}
              />
            }
          />
        </>
      }
    />
  );
}
