import "./TooltipTitle.css";

interface TooltipTitleProps {
  name: string;
}

export function TooltipTitle({ name }: TooltipTitleProps) {
  return <div className="tooltip-name">{name}</div>;
}
