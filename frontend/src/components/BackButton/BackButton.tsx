import { FiArrowLeft } from "react-icons/fi";
import "./BackButton.css";

interface BackButtonProps {
  onClick: () => void;
  label?: string;
  ariaLabel?: string;
}

export function BackButton({
  onClick,
  label = "Back",
  ariaLabel = "Back",
}: BackButtonProps) {
  return (
    <button className="back-button" onClick={onClick} aria-label={ariaLabel}>
      <FiArrowLeft className="back-button__icon" aria-hidden />
      <span>{label}</span>
    </button>
  );
}
