use serde::Serialize;

#[derive(Serialize)]
pub struct Dealer {
    pub id: String,
    pub name: String,
    pub tier: String,
    pub territory: String,
    pub latitude: f64,
    pub longitude: f64,
    pub performance: Vec<MonthlyMetrics>,
}

#[derive(Serialize)]
pub struct MonthlyMetrics {
    pub period: String,
    pub look_to_book: f64,
    pub funding_velocity: f64,
    pub exception_rate: f64,
}

#[derive(Serialize)]
pub struct Exceptions {
    pub tier: String,
    pub types: Vec<ExceptionBreakdown>,
    pub dealer_rate: f64,
    pub peer_rate: f64,
    pub why: String,
}

#[derive(Serialize)]
pub struct ExceptionBreakdown {
    pub exception_type: String,
    pub label: String,
    pub count: u64,
    pub share: f64,
}

#[derive(Serialize)]
pub struct CreditMix {
    pub tier: String,
    pub months: Vec<CreditMixMonth>,
    pub peer: CreditMixShares,
    pub why: String,
}

#[derive(Serialize)]
pub struct CreditMixMonth {
    pub period: String,
    pub prime: f64,
    pub near_prime: f64,
    pub subprime: f64,
    pub volume: u64,
}

#[derive(Serialize)]
pub struct CreditMixShares {
    pub prime: f64,
    pub near_prime: f64,
    pub subprime: f64,
}

#[derive(Serialize)]
pub struct Funding {
    pub tier: String,
    pub months: Vec<FundingMonth>,
    pub peer_avg_days: f64,
    pub why: String,
}

#[derive(Serialize)]
pub struct FundingMonth {
    pub period: String,
    pub contracts: u64,
    pub avg_funding_days: f64,
    pub slow_share: f64,
}

#[derive(Serialize)]
pub struct Servicing {
    pub tier: String,
    pub loans: u64,
    pub epd_rate: f64,
    pub peer_epd_rate: f64,
    pub dpd: DpdDistribution,
    pub why: String,
}

#[derive(Serialize)]
pub struct DpdDistribution {
    pub current: u64,
    pub days_30: u64,
    pub days_60: u64,
    pub days_90_plus: u64,
}
