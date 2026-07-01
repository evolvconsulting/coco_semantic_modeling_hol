export interface MonthlyMetrics {
  period: string;
  look_to_book: number;
  funding_velocity: number;
  exception_rate: number;
}

export interface Dealer {
  id: string;
  name: string;
  tier: string;
  territory: string;
  latitude: number;
  longitude: number;
  performance: MonthlyMetrics[];
}

export async function fetchDealers(): Promise<Dealer[]> {
  const response = await fetch("/api/dealers");
  if (!response.ok) {
    throw new Error(`Failed to load dealers: ${response.status}`);
  }
  return response.json();
}

export interface CreditMixShares {
  prime: number;
  near_prime: number;
  subprime: number;
}

export interface CreditMixMonth extends CreditMixShares {
  period: string;
  volume: number;
}

export interface CreditMix {
  tier: string;
  months: CreditMixMonth[];
  peer: CreditMixShares;
  why: string;
}

export interface FundingMonth {
  period: string;
  contracts: number;
  avg_funding_days: number;
  slow_share: number;
}

export interface Funding {
  tier: string;
  months: FundingMonth[];
  peer_avg_days: number;
  why: string;
}

export interface ExceptionBreakdown {
  exception_type: string;
  label: string;
  count: number;
  share: number;
}

export interface Exceptions {
  tier: string;
  types: ExceptionBreakdown[];
  dealer_rate: number;
  peer_rate: number;
  why: string;
}

export interface DpdDistribution {
  current: number;
  days_30: number;
  days_60: number;
  days_90_plus: number;
}

export interface Servicing {
  tier: string;
  loans: number;
  epd_rate: number;
  peer_epd_rate: number;
  dpd: DpdDistribution;
  why: string;
}

async function fetchSection<T>(id: string, section: string): Promise<T> {
  const response = await fetch(`/api/dealers/${id}/${section}`);
  if (!response.ok) {
    throw new Error(`Failed to load ${section}: ${response.status}`);
  }
  return response.json();
}

export const fetchCreditMix = (id: string) =>
  fetchSection<CreditMix>(id, "credit-mix");
export const fetchFunding = (id: string) =>
  fetchSection<Funding>(id, "funding");
export const fetchExceptions = (id: string) =>
  fetchSection<Exceptions>(id, "exceptions");
export const fetchServicing = (id: string) =>
  fetchSection<Servicing>(id, "servicing");
