from app.dealers.queries import DEALER_CREDIT_MIX, DEALER_CREDIT_MIX_PEER
from app.snowflake_client import Row, SnowflakeClient


def for_dealer(client: SnowflakeClient, dealer_id: str) -> dict:
    months_rows = client.query_with_bindings(DEALER_CREDIT_MIX, [dealer_id])
    months = _months(months_rows)

    peer_rows = client.query_with_bindings(DEALER_CREDIT_MIX_PEER, [dealer_id, dealer_id])
    peer_row = peer_rows[0] if peer_rows else None

    tier = _field(peer_row, "TIER") if peer_row else ""
    peer = {
        "prime": _number(peer_row, "PRIME") if peer_row else 0.0,
        "near_prime": _number(peer_row, "NEAR_PRIME") if peer_row else 0.0,
        "subprime": _number(peer_row, "SUBPRIME") if peer_row else 0.0,
    }

    why = _explain(months, peer, tier)

    return {
        "tier": tier,
        "months": months,
        "peer": peer,
        "why": why,
    }


def _months(rows: list[Row]) -> list[dict]:
    months: list[dict] = []

    for row in rows:
        period = _field(row, "PERIOD")
        credit_tier = _field(row, "CREDIT_TIER")
        count = _count(row)

        if months and months[-1]["period"] == period:
            month = months[-1]
        else:
            month = {
                "period": period,
                "prime": 0.0,
                "near_prime": 0.0,
                "subprime": 0.0,
                "volume": 0,
            }
            months.append(month)

        if credit_tier == "Prime":
            month["prime"] += count
        elif credit_tier == "Near_Prime":
            month["near_prime"] += count
        elif credit_tier == "Subprime":
            month["subprime"] += count
        month["volume"] += count

    for month in months:
        if month["volume"] > 0:
            total = float(month["volume"])
            month["prime"] /= total
            month["near_prime"] /= total
            month["subprime"] /= total

    return months


def _explain(months: list[dict], peer: dict, tier: str) -> str:
    if not months:
        return ""

    first, last = months[0], months[-1]

    prime_delta = (last["prime"] - first["prime"]) * 100
    sub_delta = (last["subprime"] - first["subprime"]) * 100
    prime_dir = "fell" if prime_delta < 0 else "rose"
    sub_dir = "climbed" if sub_delta >= 0 else "eased"

    trend = (
        f"Prime share {prime_dir} {first['prime'] * 100:.0f}%→{last['prime'] * 100:.0f}% "
        f"since {first['period']}, while subprime {sub_dir} "
        f"{first['subprime'] * 100:.0f}%→{last['subprime'] * 100:.0f}%."
    )

    sub_gap = (last["subprime"] - peer["subprime"]) * 100
    if abs(sub_gap) < 1.0:
        peer_clause = f"Subprime mix is in line with the Tier {tier} peer average."
    elif sub_gap > 0.0:
        peer_clause = (
            f"Subprime now sits {sub_gap:.0f}pt above the Tier {tier} peer average of "
            f"{peer['subprime'] * 100:.0f}%, a riskier pool that lifts decline rates."
        )
    else:
        peer_clause = (
            f"Subprime sits {abs(sub_gap):.0f}pt below the Tier {tier} peer average of "
            f"{peer['subprime'] * 100:.0f}%."
        )

    return f"{trend} {peer_clause}"


def _field(row: Row, column: str) -> str:
    return row.get(column) or ""


def _count(row: Row) -> int:
    value = row.get("APPLICATION_COUNT")
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
