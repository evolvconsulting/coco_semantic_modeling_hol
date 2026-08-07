# Dealer 360 HOL — single-account setup

Use this variant when **each attendee has their own Snowflake account**. The
scripts in the parent `lab_setup/` directory remain the shared-account variant
(one account, N attendees, `HOL_USER_01`–`HOL_USER_NN`) and are unchanged.

## Run order

An `ACCOUNTADMIN` runs these in each participant's account, ahead of the lab —
never the participant, never live:

| # | Script | When |
|---|--------|------|
| 1 | `hol_setup_dealer360.sql` | Ahead of the lab, **after** DataOps.live has provisioned the user. Creates everything and binds the participant. |
| 2 | `hol_verify_dealer360.sql` | After setup. Every check should pass before the lab starts. |
| 3 | *(the lab itself)* | Participant builds the semantic view with CoCo. |
| 4 | `dealer_360_semantic_view.sql` | Reference / answer key. Not part of setup. |
| 5 | `dealer_360_agent.sql` | After the semantic view exists. |
| 6 | `hol_teardown_dealer360.sql` | After the lab, or to reset and re-run setup. |

## The participant user

The participant's user is provisioned separately by **DataOps.live** and is
expected to be named `USER`. The last block of `hol_setup_dealer360.sql` grants
`HOL_PARTICIPANT` to it and sets its default role, warehouse, and namespace.

`USER` is quoted as `"USER"` throughout because it is also a Snowflake keyword —
`GRANT ROLE ... TO USER USER` does not parse. The quoting also makes it
case-sensitive: it matches a user created as `USER` or `"USER"`, but not `"user"`.

**Ordering matters now.** Setup should run after DataOps.live has created the
user. If it runs first, the bind block reports a warning and everything else still
applies — so the fix is simply to re-run setup once the user exists. The script is
idempotent; a second run reloads the seed data to identical row counts.

If the username turns out to differ, change it in the three places in that final
block. Check 8 in the verify script is the guard — it returns zero rows until the
binding exists.

**An unbound participant is recoverable but expensive.** The DataOps.live user
carries `ACCOUNTADMIN` alongside its lower-privilege default role, and
`ACCOUNTADMIN` inherits `HOL_PARTICIPANT` through `SYSADMIN` — so they can elevate
and still reach the data. That means running the whole lab as `ACCOUNTADMIN`,
though, and it costs live troubleshooting time.

That same elevation is the general escape hatch for this variant: if anything in
provisioning went wrong, the participant has the privileges to fix it in the room.
It is a fallback, not the design — no lab step should require it.

## What this variant changes

**No user provisioning; one role instead of N.** The shared-account script
creates `HOL_USER_XX` / `HOL_ROLE_XX` with a shared password so N people can
share one account. Here the participant's user comes from DataOps.live, so this
script creates no users at all — just a single `HOL_PARTICIPANT` role, bound to
that user by the final block of setup. Objects are owned by `SYSADMIN`, and
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
User Name:        USER  (provisioned by DataOps.live)
Password:         <as issued with that user>
Role:             HOL_PARTICIPANT
Warehouse:        HOL_DEALER360_WH
Database:         HOL_DEALER360
Schema:           CORE
```

If setup's bind block succeeded, role/warehouse/database are already the user's
defaults, so the participant shouldn't need to set them by hand. List them anyway
— CoCo Desktop's onboarding wizard doesn't ask for any of the three, and a
participant who needs to correct them will look for them here.

And the corresponding `backend/.env`:

```
SNOWFLAKE_ACCOUNT=<the participant's own account identifier>
SNOWFLAKE_USER=USER
SNOWFLAKE_PASSWORD=<as issued with that user>
SNOWFLAKE_WAREHOUSE=HOL_DEALER360_WH
SNOWFLAKE_ROLE=HOL_PARTICIPANT
SNOWFLAKE_DATABASE=HOL_DEALER360
SNOWFLAKE_SCHEMA=CORE
```
