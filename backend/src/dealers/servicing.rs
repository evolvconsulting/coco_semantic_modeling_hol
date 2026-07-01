use crate::dealers::dealer::{DpdDistribution, Servicing};
use crate::dealers::queries::{DEALER_SERVICING, DEALER_SERVICING_PEER};
use crate::snowflake::{Row, SnowflakeClient};

pub async fn for_dealer(client: &SnowflakeClient, dealer_id: &str) -> Result<Servicing, String> {
    let response = client
        .query_with_bindings(DEALER_SERVICING, &[dealer_id])
        .await?;
    let rows = response.rows();
    let row = rows.first().ok_or("No servicing data")?;

    let loans = int(row, "LOAN_COUNT");
    let epd_rate = number(row, "EPD_RATE");
    let dpd = DpdDistribution {
        current: int(row, "DPD_CURRENT"),
        days_30: int(row, "DPD_30"),
        days_60: int(row, "DPD_60"),
        days_90_plus: int(row, "DPD_90_PLUS"),
    };

    let peer_response = client
        .query_with_bindings(DEALER_SERVICING_PEER, &[dealer_id, dealer_id])
        .await?;
    let peer_rows = peer_response.rows();
    let peer_row = peer_rows.first();
    let tier = peer_row.map(|r| field(r, "TIER")).unwrap_or_default();
    let peer_epd_rate = peer_row.map(|r| number(r, "PEER_EPD_RATE")).unwrap_or(0.0);

    let why = explain(loans, epd_rate, peer_epd_rate, &dpd, &tier);

    Ok(Servicing {
        tier,
        loans,
        epd_rate,
        peer_epd_rate,
        dpd,
        why,
    })
}

fn explain(
    loans: u64,
    epd_rate: f64,
    peer_epd_rate: f64,
    dpd: &DpdDistribution,
    tier: &str,
) -> String {
    if loans == 0 {
        return "No servicing history yet.".to_string();
    }

    let delinquent = dpd.days_30 + dpd.days_60 + dpd.days_90_plus;
    let book = format!(
        "{loans} loans serviced, {delinquent} past due. EPD is {:.1}%",
        epd_rate * 100.0,
    );

    let peer_clause = if peer_epd_rate <= 0.0 {
        format!("{book}.")
    } else if epd_rate > peer_epd_rate * 1.1 {
        format!(
            "{book}, above the Tier {} peer average of {:.1}% and an early signal of portfolio risk.",
            tier,
            peer_epd_rate * 100.0,
        )
    } else {
        format!(
            "{book}, in line with the Tier {} peer average of {:.1}%; portfolio risk is not yet elevated.",
            tier,
            peer_epd_rate * 100.0,
        )
    };

    peer_clause
}

fn field(row: &Row, column: &str) -> String {
    row.get(column).unwrap_or_default().to_string()
}

fn int(row: &Row, column: &str) -> u64 {
    row.get(column).and_then(|v| v.parse().ok()).unwrap_or(0)
}

fn number(row: &Row, column: &str) -> f64 {
    row.get(column).and_then(|v| v.parse().ok()).unwrap_or(0.0)
}
