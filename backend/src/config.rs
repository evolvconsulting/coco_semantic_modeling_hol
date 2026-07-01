#[derive(Clone)]
pub struct SnowflakeConfig {
    pub host: String,
    pub pat: String,
    pub warehouse: String,
    pub role: String,
    pub database: String,
    pub schema: String,
}

impl SnowflakeConfig {
    pub fn from_env() -> Result<Self, String> {
        Ok(Self {
            host: required("SNOWFLAKE_HOST")?,
            pat: required("SNOWFLAKE_PAT")?,
            warehouse: required("SNOWFLAKE_WAREHOUSE")?,
            role: required("SNOWFLAKE_ROLE")?,
            database: required("SNOWFLAKE_DATABASE")?,
            schema: required("SNOWFLAKE_SCHEMA")?,
        })
    }
}

fn required(key: &str) -> Result<String, String> {
    std::env::var(key).map_err(|_| format!("Missing {key}"))
}
