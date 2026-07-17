import { useState, type CSSProperties } from "react";
import { FiChevronDown } from "react-icons/fi";
import "./DealerList.css";
import type { Dealer } from "../../api";
import { healthOf, scoreOf, type Health } from "../../health";

interface DealerListProps {
  dealers: Dealer[];
  onSelect: (dealer: Dealer) => void;
}

const TREND_EPSILON = 0.005;

const HEALTH_GRADIENTS: Record<Health, string> = {
  green: "linear-gradient(90deg, #6ee7b7 0%, #22c55e 100%)",
  yellow: "linear-gradient(90deg, #fde68a 0%, #eab308 100%)",
  red: "linear-gradient(90deg, #fca5a5 0%, #ef4444 100%)",
};

export function DealerList({ dealers, onSelect }: DealerListProps) {
  const [open, setOpen] = useState(false);

  return (
    <div className="dealer-list">
      <button
        className="dealer-list-trigger"
        onClick={() => setOpen((pv) => !pv)}
        aria-expanded={open}
      >
        <span className="dealer-list-trigger-label">Dealers</span>
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
            onSelect={onSelect}
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
  const latest = dealer.performance[dealer.performance.length - 1];
  const prior = dealer.performance[dealer.performance.length - 2] ?? latest;
  const delta = latest && prior ? scoreOf(latest) - scoreOf(prior) : 0;

  return (
    <li
      className="dealer-list-item"
      style={
        {
          "--health-gradient": HEALTH_GRADIENTS[health],
          "--stagger-delay": open ? `${Math.min(index, 5) * 0.035}s` : "0s",
        } as CSSProperties
      }
      onClick={() => onSelect(dealer)}
    >
      <span className="dealer-list-name">{dealer.name}</span>
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
