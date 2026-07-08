import os
from dataclasses import dataclass


@dataclass(frozen=True)
class SnowflakeConfig:
    host: str
    pat: str
    warehouse: str
    role: str
    database: str
    schema: str

    @staticmethod
    def from_env() -> "SnowflakeConfig":
        return SnowflakeConfig(
            host=_required("SNOWFLAKE_HOST"),
            pat=_required("SNOWFLAKE_PAT"),
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
