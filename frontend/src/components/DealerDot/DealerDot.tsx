import { useEffect, useRef } from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { Marker } from "maplibre-gl";
import { Ripples } from "ldrs/react";
import "ldrs/react/Ripples.css";
import type { Dealer } from "../../api";
import { healthOf, type Health } from "../../health";
import { HEALTH_COLORS } from "../../colors";
import { useMap } from "../MapContext/MapContext";

const SIZE = 26;

function rippleElement(health: Health): HTMLElement {
  const el = document.createElement("div");
  el.style.width = `${SIZE}px`;
  el.style.height = `${SIZE}px`;
  el.style.cursor = "pointer";
  el.innerHTML = renderToStaticMarkup(
    <Ripples size={SIZE} speed={8} color={HEALTH_COLORS[health]} />,
  );
  return el;
}

interface DealerDotProps {
  dealer: Dealer;
  onSelect: (dealer: Dealer) => void;
  onHover: (dealer: Dealer | null) => void;
}

export function DealerDot({ dealer, onSelect, onHover }: DealerDotProps) {
  const map = useMap();
  const onSelectRef = useRef(onSelect);
  const onHoverRef = useRef(onHover);
  onSelectRef.current = onSelect;
  onHoverRef.current = onHover;

  useEffect(() => {
    const health = healthOf(dealer);
    const el = rippleElement(health);

    el.addEventListener("click", (e) => {
      e.stopPropagation();
      onSelectRef.current(dealer);
    });
    el.addEventListener("mouseenter", () => onHoverRef.current(dealer));
    el.addEventListener("mouseleave", () => onHoverRef.current(null));

    const marker = new Marker({ element: el })
      .setLngLat([dealer.longitude, dealer.latitude])
      .addTo(map);

    return () => {
      marker.remove();
    };
  }, [dealer, map]);

  return null;
}
