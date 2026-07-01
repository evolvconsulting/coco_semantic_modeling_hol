use crate::config::SnowflakeConfig;
use serde::Serialize;
use std::collections::HashMap;

#[derive(Serialize)]
pub struct StatementRequest {
    pub statement: String,
    pub timeout: u32,
    pub warehouse: String,
    pub role: String,
    pub database: String,
    pub schema: String,
    #[serde(skip_serializing_if = "HashMap::is_empty")]
    pub bindings: HashMap<String, Binding>,
}

#[derive(Serialize)]
pub struct Binding {
    #[serde(rename = "type")]
    pub kind: String,
    pub value: String,
}

impl StatementRequest {
    pub fn build(statement: impl Into<String>, cfg: &SnowflakeConfig) -> Self {
        Self::build_with_bindings(statement, &[], cfg)
    }

    pub fn build_with_bindings(
        statement: impl Into<String>,
        params: &[&str],
        cfg: &SnowflakeConfig,
    ) -> Self {
        let bindings = params
            .iter()
            .enumerate()
            .map(|(i, value)| {
                (
                    (i + 1).to_string(),
                    Binding {
                        kind: "TEXT".to_string(),
                        value: value.to_string(),
                    },
                )
            })
            .collect();

        Self {
            statement: statement.into(),
            timeout: 60,
            warehouse: cfg.warehouse.clone(),
            role: cfg.role.clone(),
            database: cfg.database.clone(),
            schema: cfg.schema.clone(),
            bindings,
        }
    }
}
