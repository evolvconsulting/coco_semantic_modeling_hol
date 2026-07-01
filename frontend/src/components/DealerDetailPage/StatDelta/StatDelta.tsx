import { DeltaIndicator } from "../shared/DeltaIndicator";

interface StatDeltaProps {
  delta: number;
  higherIsBetter: boolean;
  format: (value: number) => string;
}

export function StatDelta({ delta, higherIsBetter, format }: StatDeltaProps) {
  return (
    <DeltaIndicator
      delta={delta}
      higherIsBetter={higherIsBetter}
      format={format}
      size="sm"
    />
  );
}
