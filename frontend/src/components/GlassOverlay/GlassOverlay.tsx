import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { useMap } from "../MapContext/MapContext";
import type { Dealer } from "../../api";
import { DealerTooltip } from "../DealerTooltip/DealerTooltip";

interface GlassOverlayProps {
  dealer: Dealer | null;
}

interface Point {
  x: number;
  y: number;
}

const CARD_WIDTH = 224;
const Y_OFFSET = 18;

export function GlassOverlay({ dealer }: GlassOverlayProps) {
  const map = useMap();
  const [point, setPoint] = useState<Point | null>(null);

  useEffect(() => {
    if (!dealer) {
      setPoint(null);
      return;
    }

    const update = () => {
      const p = map.project([dealer.longitude, dealer.latitude]);
      setPoint({ x: p.x, y: p.y });
    };

    update();
    map.on("move", update);
    return () => {
      map.off("move", update);
    };
  }, [dealer, map]);

  if (!dealer || !point) return null;

  const container = map.getContainer();

  return createPortal(
    <div
      className="glass-overlay"
      style={{
        left: point.x - CARD_WIDTH / 2,
        bottom: container.clientHeight - point.y + Y_OFFSET,
      }}
    >
      <DealerTooltip key={dealer.id} dealer={dealer} />
    </div>,
    container,
  );
}
