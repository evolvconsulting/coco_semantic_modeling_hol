import type { CSSProperties } from "react";
import { BackButton } from "../../BackButton/BackButton";
import { HealthBadge } from "../../Tooltip/HealthBadge/HealthBadge";
import { DetailHealthScore } from "../DetailHealthScore/DetailHealthScore";
import type { Health } from "../../../health";
import "./DetailSidebar.css";

interface DetailSidebarProps {
  name: string;
  meta: string;
  health: Health;
  score: number;
  scoreDelta: number;
  image?: string;
  onBack: () => void;
}

export function DetailSidebar({
  name,
  meta,
  health,
  score,
  scoreDelta,
  image,
  onBack,
}: DetailSidebarProps) {
  const style = image
    ? ({ "--sidebar-image": `url(${image})` } as CSSProperties)
    : undefined;

  return (
    <aside
      className={`detail-sidebar${image ? " detail-sidebar--image" : ""}`}
      style={style}
    >
      <div className="detail-sidebar-top">
        <BackButton onClick={onBack} ariaLabel="Back to map" />
        <h1 className="detail-sidebar-name">{name}</h1>
        <p className="detail-sidebar-meta">{meta}</p>
        <HealthBadge health={health} size="lg" />
      </div>
      <DetailHealthScore score={score} scoreDelta={scoreDelta} />
    </aside>
  );
}
