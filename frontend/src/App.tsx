import "maplibre-gl/dist/maplibre-gl.css";
import { useCallback, useRef, useState } from "react";
import { useDealers } from "./hooks/useDealers";
import { DealerMap } from "./components/DealerMap/DealerMap";
import { DealerDot } from "./components/DealerDot/DealerDot";
import { GlassOverlay } from "./components/GlassOverlay/GlassOverlay";
import { MapController } from "./components/MapController/MapController";
import { DealerDetailView } from "./components/DealerDetailPage/DealerDetailView/DealerDetailView";
import { AppSidebar } from "./components/AppSidebar/AppSidebar";
import type { Dealer } from "./api";
import type { Phase } from "./phase";

function App() {
  const { dealers, loading, error } = useDealers();
  const [hovered, setHovered] = useState<Dealer | null>(null);
  const [selected, setSelected] = useState<Dealer | null>(null);
  const [phase, setPhase] = useState<Phase>("map");

  const phaseRef = useRef(phase);
  phaseRef.current = phase;

  const select = useCallback((dealer: Dealer) => {
    if (phaseRef.current !== "map") return;
    setHovered(null);
    setSelected(dealer);
    setPhase("zooming-in");
  }, []);

  const onArrived = useCallback(() => setPhase("detail"), []);
  const onBack = useCallback(() => setPhase("zooming-out"), []);
  const onReturned = useCallback(() => {
    setSelected(null);
    setPhase("map");
  }, []);

  if (loading) return <p>Loading dealers…</p>;
  if (error) return <p>{error}</p>;

  return (
    <div style={{ display: "flex", height: "100vh", width: "100%" }}>
      <AppSidebar dealers={dealers} onSelectDealer={select} />
      <DealerMap>
        {dealers.map((dealer) => (
          <DealerDot
            key={dealer.id}
            dealer={dealer}
            onSelect={select}
            onHover={setHovered}
          />
        ))}
        {phase === "map" && <GlassOverlay dealer={hovered} />}
        <MapController
          selected={selected}
          phase={phase}
          onArrived={onArrived}
          onReturned={onReturned}
        />
        {(phase === "detail" || phase === "zooming-out") && selected && (
          <DealerDetailView
            dealer={selected}
            leaving={phase === "zooming-out"}
            onBack={onBack}
          />
        )}
      </DealerMap>
    </div>
  );
}

export default App;
