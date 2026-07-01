import type { Servicing } from "../../../api";
import { MetricSection } from "../MetricSection/MetricSection";
import { Stat } from "../Stat/Stat";
import { peerDeviation, percent } from "../shared/format";

interface ServicingSectionProps {
  data: Servicing;
  index?: number;
  active?: boolean;
  onHover?: (target: HTMLElement | null) => void;
}

export function ServicingSection({
  data,
  index,
  active,
  onHover,
}: ServicingSectionProps) {
  const delinquent = data.dpd.days_30 + data.dpd.days_60 + data.dpd.days_90_plus;

  return (
    <MetricSection
      label="Servicing"
      index={index}
      active={active}
      onHover={onHover}
      why={data.why}
      stats={
        <>
          <Stat
            label="EPD Rate"
            value={percent(data.epd_rate, 1)}
            sub={`peer ${percent(data.peer_epd_rate, 1)}`}
            peerDeviation={peerDeviation(
              data.epd_rate,
              data.peer_epd_rate,
              false,
            )}
          />
          <Stat label="Loans Serviced" value={`${data.loans}`} />
          <Stat label="Past Due" value={`${delinquent}`} />
        </>
      }
    />
  );
}
