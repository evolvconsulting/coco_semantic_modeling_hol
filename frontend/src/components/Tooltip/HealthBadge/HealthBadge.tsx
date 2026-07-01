import "./HealthBadge.css";
import { HEALTH_LABELS, type Health } from "../../../health";

interface HealthBadgeProps {
  health: Health;
  size?: "sm" | "lg";
}

export function HealthBadge({ health, size = "sm" }: HealthBadgeProps) {
  return (
    <div className={`health-badge health-badge--${size}`}>
      <span className="health-badge-dot" />
      <span className="health-badge-label">{HEALTH_LABELS[health]}</span>
    </div>
  );
}
