import { useEffect, useState } from "react";
import {
  fetchCreditMix,
  fetchFunding,
  fetchExceptions,
  fetchServicing,
  type CreditMix,
  type Funding,
  type Exceptions,
  type Servicing,
} from "../api";

export interface DealerDetail {
  creditMix: CreditMix;
  funding: Funding;
  exceptions: Exceptions;
  servicing: Servicing;
}

interface DealerDetailState {
  detail: DealerDetail | null;
  loading: boolean;
  error: string | null;
}

export function useDealerDetail(dealerId: string): DealerDetailState {
  const [detail, setDetail] = useState<DealerDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    setError(null);

    Promise.all([
      fetchCreditMix(dealerId),
      fetchFunding(dealerId),
      fetchExceptions(dealerId),
      fetchServicing(dealerId),
    ])
      .then(([creditMix, funding, exceptions, servicing]) => {
        if (active) setDetail({ creditMix, funding, exceptions, servicing });
      })
      .catch((e) => {
        if (active) setError(String(e));
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    return () => {
      active = false;
    };
  }, [dealerId]);

  return { detail, loading, error };
}
