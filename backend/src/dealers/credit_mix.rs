use crate::dealers::dealer::{CreditMix, CreditMixMonth, CreditMixShares};
use crate::dealers::queries::{DEALER_CREDIT_MIX, DEALER_CREDIT_MIX_PEER};
use crate::snowflake::{Row, SnowflakeClient};

pub async fn for_dealer(client: &SnowflakeClient, dealer_id: &str) -> Result<CreditMix, String> {
    let months_response = client
        .query_with_bindings(DEALER_CREDIT_MIX, &[dealer_id])
        .await?;
    let months = months(months_response.rows());

    let peer_response = client
        .query_with_bindings(DEALER_CREDIT_MIX_PEER, &[dealer_id, dealer_id])
        .await?;
    let peer_rows = peer_response.rows();
    let peer_row = peer_rows.first();

    let tier = peer_row.map(|row| field(row, "TIER")).unwrap_or_default();
    let peer = CreditMixShares {
        prime: peer_row.map(|r| number(r, "PRIME")).unwrap_or(0.0),
        near_prime: peer_row.map(|r| number(r, "NEAR_PRIME")).unwrap_or(0.0),
        subprime: peer_row.map(|r| number(r, "SUBPRIME")).unwrap_or(0.0),
    };

    let why = explain(&months, &peer, &tier);

    Ok(CreditMix {
        tier,
        months,
        peer,
        why,
    })
}

fn months(rows: Vec<Row>) -> Vec<CreditMixMonth> {
    let mut months: Vec<CreditMixMonth> = Vec::new();

    for row in rows {
        let period = field(&row, "PERIOD");
        let credit_tier = field(&row, "CREDIT_TIER");
        let count = count(&row);

        let month = match months.last_mut() {
            Some(month) if month.period == period => month,
            _ => {
                months.push(CreditMixMonth {
                    period,
                    prime: 0.0,
                    near_prime: 0.0,
                    subprime: 0.0,
                    volume: 0,
                });
                months.last_mut().unwrap()
            }
        };

        match credit_tier.as_str() {
            "Prime" => month.prime += count as f64,
            "Near_Prime" => month.near_prime += count as f64,
            "Subprime" => month.subprime += count as f64,
            _ => {}
        }
        month.volume += count;
    }

    for month in &mut months {
        if month.volume > 0 {
            let total = month.volume as f64;
            month.prime /= total;
            month.near_prime /= total;
            month.subprime /= total;
        }
    }

    months
}

fn explain(months: &[CreditMixMonth], peer: &CreditMixShares, tier: &str) -> String {
    let (Some(first), Some(last)) = (months.first(), months.last()) else {
        return String::new();
    };

    let prime_delta = (last.prime - first.prime) * 100.0;
    let sub_delta = (last.subprime - first.subprime) * 100.0;
    let prime_dir = if prime_delta < 0.0 { "fell" } else { "rose" };
    let sub_dir = if sub_delta >= 0.0 { "climbed" } else { "eased" };

    let trend = format!(
        "Prime share {} {:.0}%→{:.0}% since {}, while subprime {} {:.0}%→{:.0}%.",
        prime_dir,
        first.prime * 100.0,
        last.prime * 100.0,
        first.period,
        sub_dir,
        first.subprime * 100.0,
        last.subprime * 100.0,
    );

    let sub_gap = (last.subprime - peer.subprime) * 100.0;
    let peer_clause = if sub_gap.abs() < 1.0 {
        format!("Subprime mix is in line with the Tier {tier} peer average.")
    } else if sub_gap > 0.0 {
        format!(
            "Subprime now sits {:.0}pt above the Tier {} peer average of {:.0}%, a riskier pool that lifts decline rates.",
            sub_gap,
            tier,
            peer.subprime * 100.0,
        )
    } else {
        format!(
            "Subprime sits {:.0}pt below the Tier {} peer average of {:.0}%.",
            sub_gap.abs(),
            tier,
            peer.subprime * 100.0,
        )
    };

    format!("{trend} {peer_clause}")
}

fn field(row: &Row, column: &str) -> String {
    row.get(column).unwrap_or_default().to_string()
}

fn count(row: &Row) -> u64 {
    row.get("APPLICATION_COUNT")
        .and_then(|v| v.parse().ok())
        .unwrap_or(0)
}

fn number(row: &Row, column: &str) -> f64 {
    row.get(column).and_then(|v| v.parse().ok()).unwrap_or(0.0)
}
