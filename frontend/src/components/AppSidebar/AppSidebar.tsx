import "./AppSidebar.css";
import type { Dealer } from "../../api";
import { DealerList } from "../DealerList/DealerList";

interface AppSidebarProps {
  dealers: Dealer[];
  onSelectDealer: (dealer: Dealer) => void;
}

export function AppSidebar({ dealers, onSelectDealer }: AppSidebarProps) {
  return (
    <aside className="app-sidebar">
      <div className="app-sidebar-header">
        <h1 className="app-sidebar-title">Dealer 360</h1>
      </div>

      <div className="app-sidebar-section">
        <h2 className="app-sidebar-section-label">Critical Alerts</h2>
        <p className="app-sidebar-placeholder">No critical alerts.</p>
      </div>

      <div className="app-sidebar-section app-sidebar-section--dealers">
        <DealerList dealers={dealers} onSelect={onSelectDealer} />
      </div>
    </aside>
  );
}
