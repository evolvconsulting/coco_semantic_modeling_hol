use crate::dealers::dealer::{Dealer, MonthlyMetrics};
use crate::dealers::queries::DEALERS_WITH_PERFORMANCE;
use crate::snowflake::{Row, SnowflakeClient};

pub async fn all(client: &SnowflakeClient) -> Result<Vec<Dealer>, String> {
    let response = client.query(DEALERS_WITH_PERFORMANCE).await?;
    Ok(assemble(response.rows()))
}

fn assemble(rows: Vec<Row>) -> Vec<Dealer> {
    let mut dealers: Vec<Dealer> = Vec::new();

    for row in rows {
        let id = field(&row, "DEALER_ID");

        match dealers.last_mut() {
            Some(dealer) if dealer.id == id => dealer.performance.push(metrics(&row)),
            _ => dealers.push(dealer(&row, id)),
        }
    }

    dealers
}

fn dealer(row: &Row, id: String) -> Dealer {
    Dealer {
        id,
        name: field(row, "DEALER_NAME"),
        tier: field(row, "TIER"),
        territory: field(row, "TERRITORY"),
        latitude: number(row, "LATITUDE"),
        longitude: number(row, "LONGITUDE"),
        performance: vec![metrics(row)],
    }
}

fn metrics(row: &Row) -> MonthlyMetrics {
    MonthlyMetrics {
        period: field(row, "PERIOD"),
        look_to_book: number(row, "LOOK_TO_BOOK"),
        funding_velocity: number(row, "FUNDING_VELOCITY"),
        exception_rate: number(row, "EXCEPTION_RATE"),
    }
}

fn field(row: &Row, column: &str) -> String {
    row.get(column).unwrap_or_default().to_string()
}

fn number(row: &Row, column: &str) -> f64 {
    row.get(column).and_then(|v| v.parse().ok()).unwrap_or(0.0)
}
