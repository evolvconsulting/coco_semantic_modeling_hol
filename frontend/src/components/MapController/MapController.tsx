import { useEffect, useRef } from "react";
import type { LngLat } from "maplibre-gl";
import type { Dealer } from "../../api";
import type { Phase } from "../../phase";
import { useMap } from "../MapContext/MapContext";

const DETAIL_ZOOM = 14;
const FLY_DURATION = 1800;

interface Camera {
  center: LngLat;
  zoom: number;
}

interface MapControllerProps {
  selected: Dealer | null;
  phase: Phase;
  onArrived: () => void;
  onReturned: () => void;
}

export function MapController({
  selected,
  phase,
  onArrived,
  onReturned,
}: MapControllerProps) {
  const map = useMap();
  const home = useRef<Camera | null>(null);
  const awaiting = useRef<"in" | "out" | null>(null);

  useEffect(() => {
    if (phase === "zooming-in" && selected) {
      home.current = { center: map.getCenter(), zoom: map.getZoom() };
      awaiting.current = "in";
      map.flyTo({
        center: [selected.longitude, selected.latitude],
        zoom: DETAIL_ZOOM,
        duration: FLY_DURATION,
        essential: true,
      });
    } else if (phase === "zooming-out" && home.current) {
      awaiting.current = "out";
      map.flyTo({
        center: home.current.center,
        zoom: home.current.zoom,
        duration: FLY_DURATION,
        essential: true,
      });
    }
  }, [phase, selected, map]);

  useEffect(() => {
    const onMoveEnd = () => {
      const flight = awaiting.current;
      if (!flight) return;
      awaiting.current = null;
      if (flight === "in") onArrived();
      else onReturned();
    };

    map.on("moveend", onMoveEnd);
    return () => {
      map.off("moveend", onMoveEnd);
    };
  }, [map, onArrived, onReturned]);

  return null;
}
