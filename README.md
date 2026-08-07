# CoCo Hands On Lab — Dealer 360

**→ [Open the lab guide](https://evolvconsulting.github.io/coco_semantic_modeling_hol/hands_on_lab.html)**

A hands-on lab for building a Snowflake semantic view and Cortex agent over a
synthetic auto-lending dataset, using CoCo. Includes a React + FastAPI dealer
scorecard app that reads the same data.

## Layout

| Path | What |
|---|---|
| `hands_on_lab.html` | The lab guide (published above) |
| `lab_setup/` | Snowflake setup for a **shared** account — many attendees, one account |
| `lab_setup/single_account/` | Snowflake setup for **per-attendee** accounts — see its README |
| `dealer_360_seed_data/` | Seed CSVs, loaded by the setup scripts |
| `backend/` · `frontend/` | The dealer scorecard app |

## Running the app

Set up `backend/.env` from `backend/.env.example`, then from the repo root:

```
./run.sh        # macOS / Linux
.\run.ps1       # Windows
```

Per-platform prerequisites are in `lab_setup/SETUP-mac.md` and
`lab_setup/SETUP-windows.md`.
