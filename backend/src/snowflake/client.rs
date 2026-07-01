use crate::config::SnowflakeConfig;
use crate::snowflake::{StatementRequest, StatementResponse};
use reqwest::Client;

const STATEMENTS_PATH: &str = "/api/v2/statements";

pub struct SnowflakeClient {
    http: Client,
    config: SnowflakeConfig,
}

impl SnowflakeClient {
    pub fn new(config: SnowflakeConfig) -> Self {
        Self {
            http: Client::new(),
            config,
        }
    }

    pub async fn query(&self, sql: impl Into<String>) -> Result<StatementResponse, String> {
        self.execute(StatementRequest::build(sql, &self.config))
            .await
    }

    pub async fn query_with_bindings(
        &self,
        sql: impl Into<String>,
        params: &[&str],
    ) -> Result<StatementResponse, String> {
        self.execute(StatementRequest::build_with_bindings(sql, params, &self.config))
            .await
    }

    async fn execute(&self, body: StatementRequest) -> Result<StatementResponse, String> {
        let response = self
            .http
            .post(self.url())
            .header("Authorization", format!("Bearer {}", self.config.pat))
            .header("Content-Type", "application/json")
            .header(
                "X-Snowflake-Authorization-Token-Type",
                "PROGRAMMATIC_ACCESS_TOKEN",
            )
            .header("User-Agent", "dealer_360_api/0.1")
            .json(&body)
            .send()
            .await
            .map_err(|e| format!("Request failed: {e}"))?;

        if !response.status().is_success() {
            let status = response.status();
            let detail = response.text().await.unwrap_or_default();
            return Err(format!("Snowflake error {status}: {detail}"));
        }

        response
            .json::<StatementResponse>()
            .await
            .map_err(|e| format!("Failed to parse response: {e}"))
    }

    fn url(&self) -> String {
        format!("https://{}{}", self.config.host, STATEMENTS_PATH)
    }
}
