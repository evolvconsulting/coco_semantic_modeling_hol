import { useEffect, useState } from "react";
import { fetchDealers, type Dealer } from "../api";

interface DealersState {
  dealers: Dealer[];
  loading: boolean;
  error: string | null;
}

export function useDealers(): DealersState {
  const [dealers, setDealers] = useState<Dealer[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchDealers()
      .then(setDealers)
      .catch((e) => setError(String(e)))
      .finally(() => setLoading(false));
  }, []);

  return { dealers, loading, error };
}
