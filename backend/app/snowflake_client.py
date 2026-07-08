from typing import Sequence

import requests

from app.config import SnowflakeConfig

STATEMENTS_PATH = "/api/v2/statements"

Row = dict[str, str | None]


class SnowflakeClient:
    def __init__(self, config: SnowflakeConfig):
        self._config = config
        self._session = requests.Session()

    def query(self, sql: str) -> list[Row]:
        return self.query_with_bindings(sql, [])

    def query_with_bindings(self, sql: str, params: Sequence[str]) -> list[Row]:
        body = self._build_request(sql, params)
        return self._execute(body)

    def _build_request(self, sql: str, params: Sequence[str]) -> dict:
        bindings = {
            str(i + 1): {"type": "TEXT", "value": value}
            for i, value in enumerate(params)
        }
        body = {
            "statement": sql,
            "timeout": 60,
            "warehouse": self._config.warehouse,
            "role": self._config.role,
            "database": self._config.database,
            "schema": self._config.schema,
        }
        if bindings:
            body["bindings"] = bindings
        return body

    def _execute(self, body: dict) -> list[Row]:
        try:
            response = self._session.post(
                self._url(),
                json=body,
                headers={
                    "Authorization": f"Bearer {self._config.pat}",
                    "Content-Type": "application/json",
                    "X-Snowflake-Authorization-Token-Type": "PROGRAMMATIC_ACCESS_TOKEN",
                    "User-Agent": "dealer_360_api/0.1",
                },
            )
        except requests.RequestException as e:
            raise RuntimeError(f"Request failed: {e}") from e

        if not response.ok:
            raise RuntimeError(f"Snowflake error {response.status_code}: {response.text}")

        try:
            payload = response.json()
        except ValueError as e:
            raise RuntimeError(f"Failed to parse response: {e}") from e

        return _rows(payload)

    def _url(self) -> str:
        return f"https://{self._config.host}{STATEMENTS_PATH}"


def _rows(payload: dict) -> list[Row]:
    columns = [col["name"] for col in payload["resultSetMetaData"]["rowType"]]
    return [dict(zip(columns, cells)) for cells in payload.get("data", [])]
