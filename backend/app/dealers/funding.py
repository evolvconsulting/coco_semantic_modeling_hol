from app.dealers.queries import DEALER_FUNDING, DEALER_FUNDING_PEER
from app.snowflake_client import Row, SnowflakeClient


def for_dealer(client: SnowflakeClient, dealer_id: str) -> dict:
    months_rows = client.query_with_bindings(DEALER_FUNDING, [dealer_id])
    months = [_month(row) for row in months_rows]

    peer_rows = client.query_with_bindings(DEALER_FUNDING_PEER, [dealer_id, dealer_id])
    peer_row = peer_rows[0] if peer_rows else None

    tier = _field(peer_row, "TIER") if peer_row else ""
    peer_avg_days = _number(peer_row, "AVG_FUNDING_DAYS") if peer_row else 0.0

    why = _explain(months, peer_avg_days, tier)

    return {
        "tier": tier,
        "months": months,
        "peer_avg_days": peer_avg_days,
        "why": why,
    }


def _explain(months: list[dict], peer_avg_days: float, tier: str) -> str:
    if not months:
        return ""

    first, last = months[0], months[-1]

    trend = (
        f"Average funding time moved {first['avg_funding_days']:.1f}d→{last['avg_funding_days']:.1f}d "
        f"since {first['period']}, with {last['slow_share'] * 100:.0f}% of contracts now funding beyond 5 days."
    )

    if peer_avg_days <= 0.0:
        peer_clause = ""
    elif last["avg_funding_days"] > peer_avg_days * 1.1:
        peer_clause = (
            f" That is {last['avg_funding_days'] / peer_avg_days:.1f}× the Tier {tier} peer average "
            f"of {peer_avg_days:.1f}d; past 5 days, dealers begin routing deals to faster lenders."
        )
    else:
        peer_clause = f" That tracks the Tier {tier} peer average of {peer_avg_days:.1f}d."

    return f"{trend}{peer_clause}"


def _month(row: Row) -> dict:
    return {
        "period": _field(row, "PERIOD"),
        "contracts": _int(row, "CONTRACT_COUNT"),
        "avg_funding_days": _number(row, "AVG_FUNDING_DAYS"),
        "slow_share": _number(row, "SLOW_SHARE"),
    }


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
