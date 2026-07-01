use crate::dealers::dealer::{ExceptionBreakdown, Exceptions};
use crate::dealers::queries::{DEALER_EXCEPTIONS, DEALER_EXCEPTIONS_PEER};
use crate::snowflake::{Row, SnowflakeClient};

pub async fn for_dealer(client: &SnowflakeClient, dealer_id: &str) -> Result<Exceptions, String> {
    let types_response = client
        .query_with_bindings(DEALER_EXCEPTIONS, &[dealer_id])
        .await?;
    let types = breakdown(types_response.rows());

    let peer_response = client
        .query_with_bindings(
            DEALER_EXCEPTIONS_PEER,
            &[dealer_id, dealer_id, dealer_id, dealer_id, dealer_id],
        )
        .await?;
    let peer_rows = peer_response.rows();
    let peer_row = peer_rows.first();

    let tier = peer_row.map(|row| field(row, "TIER")).unwrap_or_default();
    let dealer_rate = peer_row.map(|r| number(r, "DEALER_RATE")).unwrap_or(0.0);
    let peer_rate = peer_row.map(|r| number(r, "PEER_RATE")).unwrap_or(0.0);

    let why = explain(&types, dealer_rate, peer_rate, &tier);

    Ok(Exceptions {
        tier,
        types,
        dealer_rate,
        peer_rate,
        why,
    })
}

fn breakdown(rows: Vec<Row>) -> Vec<ExceptionBreakdown> {
    let counts: Vec<(String, u64)> = rows
        .iter()
        .map(|row| (field(row, "EXCEPTION_TYPE"), count(row)))
        .collect();

    let total: u64 = counts.iter().map(|(_, n)| n).sum();

    counts
        .into_iter()
        .map(|(exception_type, count)| ExceptionBreakdown {
            label: humanize(&exception_type),
            share: if total == 0 {
                0.0
            } else {
                count as f64 / total as f64
            },
            exception_type,
            count,
        })
        .collect()
}

fn explain(
    types: &[ExceptionBreakdown],
    dealer_rate: f64,
    peer_rate: f64,
    tier: &str,
) -> String {
    let Some(top) = types.first() else {
        return "No documentation exceptions on funded contracts.".to_string();
    };

    let lead = format!(
        "{} leads documentation exceptions at {:.0}% of the backlog.",
        top.label,
        top.share * 100.0,
    );

    let peer_clause = if peer_rate <= 0.0 {
        format!("This dealer's exception rate is {:.0}%.", dealer_rate * 100.0)
    } else if dealer_rate > peer_rate * 1.1 {
        format!(
            "Its {:.0}% exception rate runs {:.1}× the Tier {} peer average of {:.0}%, the proximate cause of the funding slowdown.",
            dealer_rate * 100.0,
            dealer_rate / peer_rate,
            tier,
            peer_rate * 100.0,
        )
    } else {
        format!(
            "Its {:.0}% exception rate is near the Tier {} peer average of {:.0}%.",
            dealer_rate * 100.0,
            tier,
            peer_rate * 100.0,
        )
    };

    format!("{lead} {peer_clause}")
}

fn humanize(exception_type: &str) -> String {
    exception_type
        .split('_')
        .map(|word| {
            let mut chars = word.chars();
            match chars.next() {
                Some(first) => first.to_uppercase().collect::<String>() + chars.as_str(),
                None => String::new(),
            }
        })
        .collect::<Vec<_>>()
        .join(" ")
}

fn field(row: &Row, column: &str) -> String {
    row.get(column).unwrap_or_default().to_string()
}

fn count(row: &Row) -> u64 {
    row.get("EXCEPTION_COUNT")
        .and_then(|v| v.parse().ok())
        .unwrap_or(0)
}

fn number(row: &Row, column: &str) -> f64 {
    row.get(column).and_then(|v| v.parse().ok()).unwrap_or(0.0)
}
