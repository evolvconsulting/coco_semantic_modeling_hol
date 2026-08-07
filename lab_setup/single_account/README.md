# Dealer 360 HOL — single-account setup

Use this variant when **each attendee has their own Snowflake account**. The
scripts in the parent `lab_setup/` directory remain the shared-account variant
(one account, N attendees, `HOL_USER_01`–`HOL_USER_NN`) and are unchanged.

## Run order

Each attendee runs these in their own account, with `ACCOUNTADMIN`:

| # | Script | When |
|---|--------|------|
| 1 | `hol_setup_dealer360.sql` | Before the lab. Creates the warehouse, database, tables, and loads seed data. |
| 2 | `hol_verify_dealer360.sql` | Immediately after setup. Every check should pass before the lab starts. |
| 3 | *(the lab itself)* | Attendee builds the semantic view with CoCo. |
| 4 | `dealer_360_semantic_view.sql` | Reference / answer key. Not part of setup. |
| 5 | `dealer_360_agent.sql` | After the semantic view exists. |
| 6 | `hol_teardown_dealer360.sql` | After the lab, or to reset and re-run setup. |

## What this variant changes

**No attendee users or roles.** The shared-account script provisions
`HOL_USER_XX` / `HOL_ROLE_XX` with a shared password so N people can share one
account. With one account per attendee that login already exists, so creating a
second one adds a hardcoded-password account for no benefit. Objects here are
owned by `SYSADMIN`, which any `ACCOUNTADMIN` inherits.

**No `MASTER` database and no clones.** The shared script builds
`HOL_DEALER360_MASTER` and zero-copy clones it to `_01`…`_NN`. Here
there is one database, `HOL_DEALER360`, with no suffix. This also
resolves the naming mismatch in the shared variant, where the semantic view and
agent scripts point at `..._MASTER` while the attendee docs say `..._XX`.

**Single-cluster warehouse.** The shared script sets `MAX_CLUSTER_COUNT = 4` to
absorb concurrent attendee load. Multi-cluster warehouses require Enterprise
Edition or higher, so on a Standard attendee account that `CREATE WAREHOUSE`
fails and every step after it fails with it. With one user per account there is
no concurrency to scale for.

**Explicit `SNOWFLAKE.CORTEX_USER` grant.** Granted to `PUBLIC` by default in
most accounts, but granting it explicitly keeps a freshly provisioned account
from failing at the Cortex Analyst step mid-lab.

## Two things to confirm per account

**Region.** `hol_setup_dealer360.sql` sets
`CORTEX_ENABLED_CROSS_REGION = 'AWS_US'`, which assumes attendee accounts are in
an AWS US region. If accounts are provisioned on Azure/GCP or outside the US,
change that value to match — or use `ANY_REGION` if accounts will span regions.
The lab data is synthetic, so there is no residency concern with widening it.

**Edition.** Everything here works on Standard Edition. Verify Cortex features
are enabled on whatever edition the attendee accounts are provisioned at.

## Attendee-facing docs

`full_setup.txt` and `hands_on_lab.html` in the parent directory still describe
the shared-account model (`Lab Account Name: AOVNGED.EVOLV_LAB`, shared password
`Snowflake123!`, `HOL_USER_XX`). For a single-account lab those credential
blocks become:

```
Lab Account Name: <the attendee's own account identifier>
User Name:        <the attendee's own login>
Password:         <the attendee's own password>
Warehouse:        HOL_DEALER360_WH
Database:         HOL_DEALER360
Schema:           CORE
```

And the corresponding `backend/.env`:

```
SNOWFLAKE_ACCOUNT=<the attendee's own account identifier>
SNOWFLAKE_USER=<the attendee's own login>
SNOWFLAKE_PASSWORD=<the attendee's own password>
SNOWFLAKE_WAREHOUSE=HOL_DEALER360_WH
SNOWFLAKE_ROLE=SYSADMIN
SNOWFLAKE_DATABASE=HOL_DEALER360
SNOWFLAKE_SCHEMA=CORE
```
