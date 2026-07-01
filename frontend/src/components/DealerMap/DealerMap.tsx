import { useEffect, useRef, useState, type ReactNode } from "react";
import { Map as MapLibreMap } from "maplibre-gl";
import { MapContext } from "../MapContext/MapContext";

const DFW_CENTER: [number, number] = [-97.0, 32.9];
const DFW_ZOOM = 9;
const STYLE_URL =
  "https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json";

interface DealerMapProps {
  children: ReactNode;
}

export function DealerMap({ children }: DealerMapProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [map, setMap] = useState<MapLibreMap | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    const instance = new MapLibreMap({
      container: containerRef.current,
      style: STYLE_URL,
      center: DFW_CENTER,
      zoom: DFW_ZOOM,
      attributionControl: { compact: true },
    });

    instance.on("load", () => setMap(instance));

    return () => {
      instance.remove();
    };
  }, []);

  return (
    <div style={{ position: "relative", height: "100vh", width: "100%" }}>
      <div ref={containerRef} style={{ height: "100%", width: "100%" }} />
      <div
        aria-hidden
        style={{
          position: "absolute",
          inset: 0,
          pointerEvents: "none",
          background:
            "radial-gradient(120% 90% at 50% 45%, transparent 55%, rgba(0, 12, 22, 0.55) 100%)",
        }}
      />
      <MapContext.Provider value={map}>
        {map && children}
      </MapContext.Provider>
    </div>
  );
}
