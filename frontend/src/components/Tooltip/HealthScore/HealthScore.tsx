import "./HealthScore.css";

interface HealthScoreProps {
  score: number;
}

export function HealthScore({ score }: HealthScoreProps) {
  return (
    <div className="health-score">
      <div className="health-score-label">Health Score</div>
      <div className="health-score-value">{score}</div>
    </div>
  );
}
