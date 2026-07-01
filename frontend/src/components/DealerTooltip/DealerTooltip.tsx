import type { CSSProperties } from "react";
import "./DealerTooltip.css";
import type { Dealer } from "../../api";
import { healthOf, scoreOf } from "../../health";
import { HEALTH_COLORS } from "../../colors";
import { TooltipTitle } from "../Tooltip/TooltipTitle/TooltipTitle";
import { HealthBadge } from "../Tooltip/HealthBadge/HealthBadge";
import { HealthScore } from "../Tooltip/HealthScore/HealthScore";
import { Kpi } from "../Tooltip/Kpi/Kpi";

interface DealerTooltipProps {
  dealer: Dealer;
}

export function DealerTooltip({ dealer }: DealerTooltipProps) {
  const latest = dealer.performance[dealer.performance.length - 1];
  const prior = dealer.performance[dealer.performance.length - 2] ?? latest;
  const health = healthOf(dealer);
  const color = HEALTH_COLORS[health];
  const score = Math.round(scoreOf(latest) * 100);
  const style = { "--health-accent": color } as CSSProperties;

  return (
    <div className="tooltip" style={style}>
      <div className="tooltip-aside">
        <div className="tooltip-aside-top">
          <TooltipTitle name={dealer.name} />
          <HealthBadge health={health} />
        </div>
        <HealthScore score={score} />
      </div>
      <div className="tooltip-main">
        <Kpi
          label="Look to Book"
          value={latest.look_to_book}
          prior={prior.look_to_book}
          format="percent"
          higherIsBetter
        />
        <Kpi
          label="Funding Velocity"
          value={latest.funding_velocity}
          prior={prior.funding_velocity}
          format="days"
          higherIsBetter={false}
        />
        <Kpi
          label="Exception Rate"
          value={latest.exception_rate}
          prior={prior.exception_rate}
          format="percent"
          higherIsBetter={false}
        />
      </div>
    </div>
  );
}
