import { useState } from "react";
import { FiChevronDown } from "react-icons/fi";
import "./DealerListDropdown.css";
import type { Dealer } from "../../api";
import { healthOf, scoreOf, HEALTH_LABELS } from "../../health";
import { HEALTH_COLORS } from "../../colors";

interface DealerListDropdownProps {
  dealers: Dealer[];
  onSelect: (dealer: Dealer) => void;
}

const TREND_EPSILON = 0.005;

export function DealerListDropdown({
  dealers,
  onSelect,
}: DealerListDropdownProps) {
  const [open, setOpen] = useState(false);

  return (
    <div className="dealer-list-dropdown">
      <button
        className="dealer-list-trigger"
        onClick={() => setOpen((pv) => !pv)}
        aria-expanded={open}
      >
        <span>Dealers</span>
        <FiChevronDown
          className={`dealer-list-chevron ${open ? "is-open" : ""}`}
        />
      </button>

      <ul className={`dealer-list-menu ${open ? "is-open" : ""}`}>
        {dealers.map((dealer, i) => (
          <DealerListItem
            key={dealer.id}
            dealer={dealer}
            index={i}
            open={open}
            onSelect={(d) => {
              setOpen(false);
              onSelect(d);
            }}
          />
        ))}
      </ul>
    </div>
  );
}

function DealerListItem({
  dealer,
  index,
  open,
  onSelect,
}: {
  dealer: Dealer;
  index: number;
  open: boolean;
  onSelect: (dealer: Dealer) => void;
}) {
  const health = healthOf(dealer);
  const color = HEALTH_COLORS[health];
  const latest = dealer.performance[dealer.performance.length - 1];
  const prior = dealer.performance[dealer.performance.length - 2] ?? latest;
  const delta = latest && prior ? scoreOf(latest) - scoreOf(prior) : 0;

  return (
    <li
      className="dealer-list-item"
      style={{
        "--health-accent": color,
        "--stagger-delay": open ? `${index * 0.035}s` : "0s",
      } as React.CSSProperties}
      onClick={() => onSelect(dealer)}
    >
      <span className="dealer-list-dot" />
      <span className="dealer-list-name">{dealer.name}</span>
      <span className="dealer-list-health">{HEALTH_LABELS[health]}</span>
      <Trend delta={delta} />
    </li>
  );
}

function Trend({ delta }: { delta: number }) {
  if (Math.abs(delta) < TREND_EPSILON) {
    return <span className="dealer-list-trend is-flat">—</span>;
  }

  const rising = delta > 0;

  return (
    <span className={`dealer-list-trend ${rising ? "is-good" : "is-bad"}`}>
      {rising ? "▲" : "▼"}
    </span>
  );
}
