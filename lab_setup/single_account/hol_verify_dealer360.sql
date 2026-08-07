-- Dealer 360 HOL — SINGLE ACCOUNT verification
--
-- Run after hol_setup_dealer360.sql. Every check below should pass before the
-- lab starts. There is no attendee-isolation check in this variant — isolation
-- is provided by the account boundary, not by per-attendee roles.

USE ROLE ACCOUNTADMIN;

-- 1. Warehouse exists, single cluster, auto-suspend on.
SHOW WAREHOUSES LIKE 'HOL_DEALER360_WH';
SELECT
    "name" AS warehouse_name,
    "size",
    "min_cluster_count",
    "max_cluster_count",
    "auto_suspend",
    "auto_resume"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- 2. Cortex cross-region inference is set. Expect a non-DISABLED value that
--    matches the region this account lives in.
SHOW PARAMETERS LIKE 'CORTEX_ENABLED_CROSS_REGION' IN ACCOUNT;

-- 3. The participant role holds all three Cortex database roles. CoCo Desktop
--    needs COPILOT_USER plus CORTEX_USER/CORTEX_AGENT_USER; missing any of these
--    lets sign-in succeed but leaves the agent non-functional mid-lab.
--    Expect exactly 3 rows.
SHOW GRANTS TO ROLE HOL_PARTICIPANT;
SELECT "granted_on", "name"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "granted_on" = 'DATABASE_ROLE'
  AND "name" IN ('SNOWFLAKE.CORTEX_USER', 'SNOWFLAKE.CORTEX_AGENT_USER', 'SNOWFLAKE.COPILOT_USER')
ORDER BY "name";

-- 4. Git integration fetched the seed CSVs. Expect 5 files.
SHOW GIT REPOSITORIES LIKE 'HOL_GIT_REPO' IN SCHEMA HOL_DEALER360.CORE;
LIST @HOL_DEALER360.CORE.HOL_GIT_REPO/branches/main/dealer_360_seed_data/;

-- 5. Staged copies of the seed CSVs. Expect the same 5 files.
LIST @HOL_DEALER360.CORE.HOL_SEED_STAGE;

-- 6. Tables are present and loaded. Every count must be non-zero.
SELECT 'DEALER_MASTER' AS table_name, COUNT(*) AS row_count FROM HOL_DEALER360.CORE.DEALER_MASTER
UNION ALL
SELECT 'APPLICATION_EVENTS', COUNT(*) FROM HOL_DEALER360.CORE.APPLICATION_EVENTS
UNION ALL
SELECT 'DEALER_PERFORMANCE', COUNT(*) FROM HOL_DEALER360.CORE.DEALER_PERFORMANCE
UNION ALL
SELECT 'FUNDING_EVENTS', COUNT(*) FROM HOL_DEALER360.CORE.FUNDING_EVENTS
UNION ALL
SELECT 'SERVICING_EVENTS', COUNT(*) FROM HOL_DEALER360.CORE.SERVICING_EVENTS
ORDER BY table_name;

-- 7. Referential integrity of the seeded data — every child row resolves to a
--    dealer. All three counts must be 0.
SELECT 'orphan_applications' AS check_name, COUNT(*) AS bad_rows
FROM HOL_DEALER360.CORE.APPLICATION_EVENTS a
LEFT JOIN HOL_DEALER360.CORE.DEALER_MASTER d ON a.DEALER_ID = d.DEALER_ID
WHERE d.DEALER_ID IS NULL
UNION ALL
SELECT 'orphan_contracts', COUNT(*)
FROM HOL_DEALER360.CORE.FUNDING_EVENTS f
LEFT JOIN HOL_DEALER360.CORE.DEALER_MASTER d ON f.DEALER_ID = d.DEALER_ID
WHERE d.DEALER_ID IS NULL
UNION ALL
SELECT 'orphan_servicing', COUNT(*)
FROM HOL_DEALER360.CORE.SERVICING_EVENTS s
LEFT JOIN HOL_DEALER360.CORE.FUNDING_EVENTS f ON s.CONTRACT_ID = f.CONTRACT_ID
WHERE f.CONTRACT_ID IS NULL;

-- 8. HOL_PARTICIPANT is bound to a user. This is the one check that fails until
--    bind_participant.sql has run, which cannot happen until DataOps.live has
--    provisioned the participant's user. Expect at least one row; zero rows means
--    the participant can sign in but the lab will not work for them.
SHOW GRANTS OF ROLE HOL_PARTICIPANT;
SELECT "grantee_name" AS bound_to_user
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "granted_to" = 'USER';

-- 9. End-to-end smoke test as the role the participant will actually connect as.
--    A facilitator holding ACCOUNTADMIN inherits HOL_PARTICIPANT, so this works
--    before the user binding exists.
USE ROLE HOL_PARTICIPANT;
USE WAREHOUSE HOL_DEALER360_WH;

SELECT d.TIER, COUNT(*) AS dealers, AVG(p.LOOK_TO_BOOK) AS avg_look_to_book
FROM HOL_DEALER360.CORE.DEALER_MASTER d
JOIN HOL_DEALER360.CORE.DEALER_PERFORMANCE p ON d.DEALER_ID = p.DEALER_ID
GROUP BY d.TIER
ORDER BY d.TIER;

USE ROLE ACCOUNTADMIN;
