from app.dealers.queries import DEALER_SERVICING, DEALER_SERVICING_PEER
from app.snowflake_client import Row, SnowflakeClient


def for_dealer(client: SnowflakeClient, dealer_id: str) -> dict:
    rows = client.query_with_bindings(DEALER_SERVICING, [dealer_id])
    if not rows:
        raise RuntimeError("No servicing data")
    row = rows[0]

    loans = _int(row, "LOAN_COUNT")
    epd_rate = _number(row, "EPD_RATE")
    dpd = {
        "current": _int(row, "DPD_CURRENT"),
        "days_30": _int(row, "DPD_30"),
        "days_60": _int(row, "DPD_60"),
        "days_90_plus": _int(row, "DPD_90_PLUS"),
    }

    peer_rows = client.query_with_bindings(DEALER_SERVICING_PEER, [dealer_id, dealer_id])
    peer_row = peer_rows[0] if peer_rows else None
    tier = _field(peer_row, "TIER") if peer_row else ""
    peer_epd_rate = _number(peer_row, "PEER_EPD_RATE") if peer_row else 0.0

    why = _explain(loans, epd_rate, peer_epd_rate, dpd, tier)

    return {
        "tier": tier,
        "loans": loans,
        "epd_rate": epd_rate,
        "peer_epd_rate": peer_epd_rate,
        "dpd": dpd,
        "why": why,
    }


def _explain(loans: int, epd_rate: float, peer_epd_rate: float, dpd: dict, tier: str) -> str:
    if loans == 0:
        return "No servicing history yet."

    delinquent = dpd["days_30"] + dpd["days_60"] + dpd["days_90_plus"]
    book = f"{loans} loans serviced, {delinquent} past due. EPD is {epd_rate * 100:.1f}%"

    if peer_epd_rate <= 0.0:
        return f"{book}."
    if epd_rate > peer_epd_rate * 1.1:
        return (
            f"{book}, above the Tier {tier} peer average of {peer_epd_rate * 100:.1f}% "
            f"and an early signal of portfolio risk."
        )
    return (
        f"{book}, in line with the Tier {tier} peer average of {peer_epd_rate * 100:.1f}%; "
        f"portfolio risk is not yet elevated."
    )


def _field(row: Row, column: str) -> str:
    return row.get(column) or ""


def _int(row: Row, column: str) -> int:
    value = row.get(column)
    try:
        return int(value)
    except (TypeError, ValueError):
        return 0


def _number(row: Row, column: str) -> float:
    value = row.get(column)
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0
