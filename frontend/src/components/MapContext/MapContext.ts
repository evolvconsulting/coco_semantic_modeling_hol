import { createContext, useContext } from "react";
import type { Map as MapLibreMap } from "maplibre-gl";

export const MapContext = createContext<MapLibreMap | null>(null);

export function useMap(): MapLibreMap {
  const map = useContext(MapContext);
  if (!map) throw new Error("useMap must be used within <DealerMap>");
  return map;
}
