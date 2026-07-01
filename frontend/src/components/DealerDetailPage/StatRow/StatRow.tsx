import type { ReactNode } from "react";
import "./StatRow.css";

interface StatRowProps {
  children: ReactNode;
}

export function StatRow({ children }: StatRowProps) {
  return <div className="stat-row">{children}</div>;
}
