from app.dealers.queries import DEALER_EXCEPTIONS, DEALER_EXCEPTIONS_PEER
from app.snowflake_client import Row, SnowflakeClient


def for_dealer(client: SnowflakeClient, dealer_id: str) -> dict:
    types_rows = client.query_with_bindings(DEALER_EXCEPTIONS, [dealer_id])
    types = _breakdown(types_rows)

    peer_rows = client.query_with_bindings(
        DEALER_EXCEPTIONS_PEER,
        [dealer_id, dealer_id, dealer_id, dealer_id, dealer_id],
    )
    peer_row = peer_rows[0] if peer_rows else None

    tier = _field(peer_row, "TIER") if peer_row else ""
    dealer_rate = _number(peer_row, "DEALER_RATE") if peer_row else 0.0
    peer_rate = _number(peer_row, "PEER_RATE") if peer_row else 0.0

    why = _explain(types, dealer_rate, peer_rate, tier)

    return {
        "tier": tier,
        "types": types,
        "dealer_rate": dealer_rate,
        "peer_rate": peer_rate,
        "why": why,
    }


def _breakdown(rows: list[Row]) -> list[dict]:
    counts = [(_field(row, "EXCEPTION_TYPE"), _count(row)) for row in rows]
    total = sum(n for _, n in counts)

    return [
        {
            "exception_type": exception_type,
            "label": _humanize(exception_type),
            "count": count,
            "share": (count / total) if total else 0.0,
        }
        for exception_type, count in counts
    ]


def _explain(types: list[dict], dealer_rate: float, peer_rate: float, tier: str) -> str:
    if not types:
        return "No documentation exceptions on funded contracts."

    top = types[0]
    lead = f"{top['label']} leads documentation exceptions at {top['share'] * 100:.0f}% of the backlog."

    if peer_rate <= 0.0:
        peer_clause = f"This dealer's exception rate is {dealer_rate * 100:.0f}%."
    elif dealer_rate > peer_rate * 1.1:
        peer_clause = (
            f"Its {dealer_rate * 100:.0f}% exception rate runs {dealer_rate / peer_rate:.1f}× "
            f"the Tier {tier} peer average of {peer_rate * 100:.0f}%, the proximate cause of the funding slowdown."
        )
    else:
        peer_clause = (
            f"Its {dealer_rate * 100:.0f}% exception rate is near the Tier {tier} peer average "
            f"of {peer_rate * 100:.0f}%."
        )

    return f"{lead} {peer_clause}"


def _humanize(exception_type: str) -> str:
    return " ".join(word[:1].upper() + word[1:] for word in exception_type.split("_") if word)


def _field(row: Row, column: str) -> str:
    return row.get(column) or ""


def _count(row: Row) -> int:
    value = row.get("EXCEPTION_COUNT")
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
