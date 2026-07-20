from typing import Sequence

import snowflake.connector

from app.config import SnowflakeConfig

snowflake.connector.paramstyle = "qmark"

Row = dict[str, str | None]


class SnowflakeClient:
    def __init__(self, config: SnowflakeConfig):
        self._config = config

    def query(self, sql: str) -> list[Row]:
        return self.query_with_bindings(sql, [])

    def query_with_bindings(self, sql: str, params: Sequence[str]) -> list[Row]:
        try:
            conn = snowflake.connector.connect(
                account=self._config.account,
                user=self._config.user,
                password=self._config.password,
                warehouse=self._config.warehouse,
                role=self._config.role,
                database=self._config.database,
                schema=self._config.schema,
            )
        except snowflake.connector.errors.Error as e:
            raise RuntimeError(f"Snowflake connection failed: {e}") from e

        try:
            cursor = conn.cursor(snowflake.connector.DictCursor)
            try:
                cursor.execute(sql, tuple(params))
                return cursor.fetchall()
            finally:
                cursor.close()
        except snowflake.connector.errors.Error as e:
            raise RuntimeError(f"Snowflake query failed: {e}") from e
        finally:
            conn.close()
