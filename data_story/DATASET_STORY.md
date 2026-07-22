# Dealer 360 Dataset Summary

## Summary

15 of 16 dealers are performing within expected ranges for their tier. One dealer, Brody's Toyota of Celina (D4471, Tier 1), is deteriorating across look-to-book, funding velocity, and exception rate. Root cause: a shift in application credit mix toward Near-Prime and Subprime, which raises decline rates and generates a larger documentation-stipulation backlog that slows funding.

## Dealer Score

Each dealer has a composite score (look-to-book, funding velocity, exception rate), used to flag dealers on the territory map.

## Peer Baseline

**Tier 1** (5 dealers, 700+ apps/quarter): look-to-book 44–56%; funding velocity 1.5–1.8 days; exception rate 6–8%; EPD <2%.

**Tier 2** (7 dealers, 300–360 apps/quarter): look-to-book 35–43%; funding velocity 2.7–2.9 days; exception rate 10–15%.

**Tier 3** (3 independents, lower volume): look-to-book 30–35%; exception rate 18–32%. Higher and more variable, but no deterioration trend.

D4471 is a Tier 1 dealer and should track the Tier 1 baseline. It did for roughly the first 30 days (late Mar–early Apr): look-to-book ~41%, funding velocity 2.2 days, exception rate 12%. It has declined each month since.

## D4471 — Key Metrics by Month

| Metric | Apr | May | Jun |
|---|---|---|---|
| Look-to-book | 40.9% | 31.7% | 27.9% |
| Funding velocity | 2.21 d | 4.26 d | 5.28 d |
| Exception rate | ~16% | ~31% | ~30%+ |
| Applications | 252 | 262 | 208 (through Jun 25) |

Prime share fell from ~66% (late Mar) to ~54% (late Jun). Subprime rose from ~11% to ~25% over the same window.

## Why Each Metric Moved

**Look-to-book (down 40.9% → 27.9%):**
Fewer applications convert to funded contracts. The application pool shifted toward Near-Prime and Subprime (Prime share -~12 pts; Subprime +~14 pts), so the lender declined a higher share. Application volume held steady; conversion did not.

**Funding velocity (up 2.21 → 5.28 days):**
Time from contract to funding roughly doubled. Driven by a rising exception backlog (below). By June, average funding time crossed 5 days, the point at which dealers begin routing deals to faster lenders.

**Exception rate (up ~12% → ~30%):**
Share of contracts held for a documentation problem. Three exception types account for the increase:
- **Income Verification** — income docs missing, inconsistent, or insufficient.
- **Proof of Residence** — address documents missing or not matching the application.
- **Document Error** — documents wrong, expired, or inconsistent (mismatched names, stale pay stubs, e-contracting data-entry mistakes).

Riskier (Near-Prime/Subprime) applicants more often have thin, hard-to-verify files, so they generate more stipulations even when submitted digitally. The backlog is the proximate cause of the funding slowdown.

**EPD (3.4%, elevated):**
Early payment default rate, above every other Tier 1 dealer (1.0–2.3%) and the 1% warning threshold. Servicing data is still early (most loans <90 days old), but EPD is the earliest leading indicator of portfolio risk and is already elevated, which is consistent with the riskier credit mix.

## Root Cause

Upstream driver is the credit-mix shift. As Prime share fell and Near-Prime/Subprime grew, decline rates rose (look-to-book down) and every documentation exception type rose with it (exception rate and funding velocity up). EPD is the early portfolio signal of the same shift.

## Data Model

| Table | Rows | Description |
|---|---|---|
| `DEALER_MASTER` | 16 | One row per dealer; DFW coordinates, tier, territory, RM assignment. |
| `APPLICATION_EVENTS` | 7,334 | Applications; credit tier, decision, requested amount/term. |
| `FUNDING_EVENTS` | 3,217 | One row per booked contract; exception type, contract date, funded date (null if in transit). |
| `SERVICING_EVENTS` | 4,038 | Payment events for funded loans; DPD status, EPD flag. |
| `DEALER_PERFORMANCE` | 48 | Monthly rollup (Apr, May, Jun) per dealer; volume, look-to-book, funding velocity, charge-off contribution. |

**Total:** 14,653 rows across 5 tables. Date range: March 28 – June 25, 2026.
