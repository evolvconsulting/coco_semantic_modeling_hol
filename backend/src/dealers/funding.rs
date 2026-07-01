use crate::dealers::dealer::{Funding, FundingMonth};
use crate::dealers::queries::{DEALER_FUNDING, DEALER_FUNDING_PEER};
use crate::snowflake::{Row, SnowflakeClient};

pub async fn for_dealer(client: &SnowflakeClient, dealer_id: &str) -> Result<Funding, String> {
    let months_response = client
        .query_with_bindings(DEALER_FUNDING, &[dealer_id])
        .await?;
    let months: Vec<FundingMonth> = months_response.rows().iter().map(month).collect();

    let peer_response = client
        .query_with_bindings(DEALER_FUNDING_PEER, &[dealer_id, dealer_id])
        .await?;
    let peer_rows = peer_response.rows();
    let peer_row = peer_rows.first();

    let tier = peer_row.map(|row| field(row, "TIER")).unwrap_or_default();
    let peer_avg_days = peer_row.map(|r| number(r, "AVG_FUNDING_DAYS")).unwrap_or(0.0);

    let why = explain(&months, peer_avg_days, &tier);

    Ok(Funding {
        tier,
        months,
        peer_avg_days,
        why,
    })
}

fn explain(months: &[FundingMonth], peer_avg_days: f64, tier: &str) -> String {
    let (Some(first), Some(last)) = (months.first(), months.last()) else {
        return String::new();
    };

    let trend = format!(
        "Average funding time moved {:.1}d→{:.1}d since {}, with {:.0}% of contracts now funding beyond 5 days.",
        first.avg_funding_days,
        last.avg_funding_days,
        first.period,
        last.slow_share * 100.0,
    );

    let peer_clause = if peer_avg_days <= 0.0 {
        String::new()
    } else if last.avg_funding_days > peer_avg_days * 1.1 {
        format!(
            " That is {:.1}× the Tier {} peer average of {:.1}d; past 5 days, dealers begin routing deals to faster lenders.",
            last.avg_funding_days / peer_avg_days,
            tier,
            peer_avg_days,
        )
    } else {
        format!(
            " That tracks the Tier {tier} peer average of {peer_avg_days:.1}d."
        )
    };

    format!("{trend}{peer_clause}")
}

fn month(row: &Row) -> FundingMonth {
    FundingMonth {
        period: field(row, "PERIOD"),
        contracts: int(row, "CONTRACT_COUNT"),
        avg_funding_days: number(row, "AVG_FUNDING_DAYS"),
        slow_share: number(row, "SLOW_SHARE"),
    }
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
