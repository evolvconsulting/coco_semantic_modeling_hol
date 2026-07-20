import os
from dataclasses import dataclass


@dataclass(frozen=True)
class SnowflakeConfig:
    account: str
    user: str
    password: str
    warehouse: str
    role: str
    database: str
    schema: str

    @staticmethod
    def from_env() -> "SnowflakeConfig":
        return SnowflakeConfig(
            account=_required("SNOWFLAKE_ACCOUNT"),
            user=_required("SNOWFLAKE_USER"),
            password=_required("SNOWFLAKE_PASSWORD"),
            warehouse=_required("SNOWFLAKE_WAREHOUSE"),
            role=_required("SNOWFLAKE_ROLE"),
            database=_required("SNOWFLAKE_DATABASE"),
            schema=_required("SNOWFLAKE_SCHEMA"),
        )


def _required(key: str) -> str:
    value = os.environ.get(key)
    if not value:
        raise RuntimeError(f"Missing {key}")
    return value
