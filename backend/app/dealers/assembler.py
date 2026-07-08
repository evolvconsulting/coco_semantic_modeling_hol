from app.dealers.queries import DEALERS_WITH_PERFORMANCE
from app.snowflake_client import Row, SnowflakeClient


def all(client: SnowflakeClient) -> list[dict]:
    rows = client.query(DEALERS_WITH_PERFORMANCE)
    return _assemble(rows)


def _assemble(rows: list[Row]) -> list[dict]:
    dealers: list[dict] = []

    for row in rows:
        id_ = _field(row, "DEALER_ID")

        if dealers and dealers[-1]["id"] == id_:
            dealers[-1]["performance"].append(_metrics(row))
        else:
            dealers.append(_dealer(row, id_))

    return dealers


def _dealer(row: Row, id_: str) -> dict:
    return {
        "id": id_,
        "name": _field(row, "DEALER_NAME"),
        "tier": _field(row, "TIER"),
        "territory": _field(row, "TERRITORY"),
        "latitude": _number(row, "LATITUDE"),
        "longitude": _number(row, "LONGITUDE"),
        "performance": [_metrics(row)],
    }


def _metrics(row: Row) -> dict:
    return {
        "period": _field(row, "PERIOD"),
        "look_to_book": _number(row, "LOOK_TO_BOOK"),
        "funding_velocity": _number(row, "FUNDING_VELOCITY"),
        "exception_rate": _number(row, "EXCEPTION_RATE"),
    }


def _field(row: Row, column: str) -> str:
    return row.get(column) or ""


def _number(row: Row, column: str) -> float:
    value = row.get(column)
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0
