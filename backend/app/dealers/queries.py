from pathlib import Path

SQL_DIR = Path(__file__).resolve().parent.parent / "sql"


def _load(name: str) -> str:
    return (SQL_DIR / name).read_text()


DEALERS_WITH_PERFORMANCE = _load("dealers_with_performance.sql")
DEALER_EXCEPTIONS = _load("dealer_exceptions.sql")
DEALER_EXCEPTIONS_PEER = _load("dealer_exceptions_peer.sql")
DEALER_CREDIT_MIX = _load("dealer_credit_mix.sql")
DEALER_CREDIT_MIX_PEER = _load("dealer_credit_mix_peer.sql")
DEALER_FUNDING = _load("dealer_funding.sql")
DEALER_FUNDING_PEER = _load("dealer_funding_peer.sql")
DEALER_SERVICING = _load("dealer_servicing.sql")
DEALER_SERVICING_PEER = _load("dealer_servicing_peer.sql")
