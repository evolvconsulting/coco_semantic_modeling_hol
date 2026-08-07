# Dealer 360 HOL — single-account setup

Use this variant when **each attendee has their own Snowflake account**. The
scripts in the parent `lab_setup/` directory remain the shared-account variant
(one account, N attendees, `HOL_USER_01`–`HOL_USER_NN`) and are unchanged.

## Run order

An `ACCOUNTADMIN` runs these in each participant's account, ahead of the lab —
never the participant, never live:

| # | Script | When |
|---|--------|------|
| 1 | `hol_setup_dealer360.sql` | Ahead of the lab. Creates the warehouse, `HOL_PARTICIPANT` role, database, tables, and loads seed data. |
| 2 | `bind_participant.sql` | Once DataOps.live has provisioned the participant's user. **Required** — see below. |
| 3 | `hol_verify_dealer360.sql` | After both. Every check should pass before the lab starts. |
| 4 | *(the lab itself)* | Participant builds the semantic view with CoCo. |
| 5 | `dealer_360_semantic_view.sql` | Reference / answer key. Not part of setup. |
| 6 | `dealer_360_agent.sql` | After the semantic view exists. |
| 7 | `hol_teardown_dealer360.sql` | After the lab, or to reset and re-run setup. |

## The two-step user binding

The participant's user is provisioned separately by **DataOps.live**, and its name
isn't known when setup runs. So the two concerns are split:

- `hol_setup_dealer360.sql` creates `HOL_PARTICIPANT` and grants it everything the
  lab needs — warehouse, database, schema, tables, and all three Cortex database
  roles. It binds the role to nobody.
- `bind_participant.sql` takes the username, grants the role to that user, and sets
  the user's default role, warehouse, and namespace. This is one edit and one run.

Splitting it this way means setup doesn't block on DataOps.live, and the username
appears in exactly one place. Check 8 in the verify script is the guard — it
returns zero rows until the binding exists.

**Skipping step 2 is recoverable but expensive.** The DataOps.live user carries
`ACCOUNTADMIN` alongside its lower-privilege default role, and `ACCOUNTADMIN`
inherits `HOL_PARTICIPANT` through `SYSADMIN` — so an unbound participant can
elevate and still reach the data. That means running the whole lab as
`ACCOUNTADMIN`, though, and it costs live troubleshooting time. Bind ahead of time.

That same elevation is the general escape hatch for this variant: if anything in
provisioning went wrong, the participant has the privileges to fix it in the room.
It is a fallback, not the design — no lab step should require it.

## What this variant changes

**No user provisioning; one role instead of N.** The shared-account script
creates `HOL_USER_XX` / `HOL_ROLE_XX` with a shared password so N people can
share one account. Here the participant's user comes from DataOps.live, so this
script creates no users at all — just a single `HOL_PARTICIPANT` role, bound to
that user by `bind_participant.sql`. Objects are owned by `SYSADMIN`, and
`HOL_PARTICIPANT` is granted to `SYSADMIN` so a facilitator with `ACCOUNTADMIN`
inherits it and can dry-run the lab exactly as the participant will see it.

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

**All three Cortex database roles granted explicitly.** `CORTEX_USER` is granted
to `PUBLIC` by default in most accounts, but a freshly provisioned account can't
be assumed to have it, and CoCo Desktop additionally requires `COPILOT_USER`
plus `CORTEX_AGENT_USER`. Missing any of them lets sign-in succeed while leaving
the agent non-functional — a failure that surfaces mid-lab, not at setup. The
shared-account script still grants none of these.

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
Lab Account Name: <the participant's own account identifier>
User Name:        <the DataOps.live-provisioned username>
Password:         <as issued with that user>
Role:             HOL_PARTICIPANT
Warehouse:        HOL_DEALER360_WH
Database:         HOL_DEALER360
Schema:           CORE
```

If `bind_participant.sql` has run, role/warehouse/database are already the user's
defaults, so the participant shouldn't need to set them by hand. List them anyway
— CoCo Desktop's onboarding wizard doesn't ask for any of the three, and a
participant who needs to correct them will look for them here.

And the corresponding `backend/.env`:

```
SNOWFLAKE_ACCOUNT=<the participant's own account identifier>
SNOWFLAKE_USER=<the DataOps.live-provisioned username>
SNOWFLAKE_PASSWORD=<as issued with that user>
SNOWFLAKE_WAREHOUSE=HOL_DEALER360_WH
SNOWFLAKE_ROLE=HOL_PARTICIPANT
SNOWFLAKE_DATABASE=HOL_DEALER360
SNOWFLAKE_SCHEMA=CORE
```
