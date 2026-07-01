import { DeltaIndicator } from "../shared/DeltaIndicator";
import "./DetailHealthScore.css";

interface DetailHealthScoreProps {
  score: number;
  scoreDelta: number;
}

export function DetailHealthScore({ score, scoreDelta }: DetailHealthScoreProps) {
  return (
    <div className="detail-score">
      <div className="detail-score-label">Dealer Health</div>
      <div className="detail-score-row">
        <span className="detail-score-value">{score}</span>
        <DeltaIndicator
          delta={scoreDelta}
          higherIsBetter
          format={(v) => `${v} vs prior`}
          size="lg"
        />
      </div>
      <div className="detail-score-meta">Composite of look-to-book, funding &amp; exceptions</div>
    </div>
  );
}
