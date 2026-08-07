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

-- 3. Cortex Analyst access is in place for the role the attendee will use.
SHOW GRANTS TO ROLE SYSADMIN;

-- 4. Git integration fetched the seed CSVs. Expect 5 files.
SHOW GIT REPOSITORIES LIKE 'HOL_GIT_REPO' IN SCHEMA COCO_SDLC_HOL_DEALER.CORE;
LIST @COCO_SDLC_HOL_DEALER.CORE.HOL_GIT_REPO/branches/main/dealer_360_seed_data/;

-- 5. Staged copies of the seed CSVs. Expect the same 5 files.
LIST @COCO_SDLC_HOL_DEALER.CORE.HOL_SEED_STAGE;

-- 6. Tables are present and loaded. Every count must be non-zero.
SELECT 'DEALER_MASTER' AS table_name, COUNT(*) AS row_count FROM COCO_SDLC_HOL_DEALER.CORE.DEALER_MASTER
UNION ALL
SELECT 'APPLICATION_EVENTS', COUNT(*) FROM COCO_SDLC_HOL_DEALER.CORE.APPLICATION_EVENTS
UNION ALL
SELECT 'DEALER_PERFORMANCE', COUNT(*) FROM COCO_SDLC_HOL_DEALER.CORE.DEALER_PERFORMANCE
UNION ALL
SELECT 'FUNDING_EVENTS', COUNT(*) FROM COCO_SDLC_HOL_DEALER.CORE.FUNDING_EVENTS
UNION ALL
SELECT 'SERVICING_EVENTS', COUNT(*) FROM COCO_SDLC_HOL_DEALER.CORE.SERVICING_EVENTS
ORDER BY table_name;

-- 7. Referential integrity of the seeded data — every child row resolves to a
--    dealer. All three counts must be 0.
SELECT 'orphan_applications' AS check_name, COUNT(*) AS bad_rows
FROM COCO_SDLC_HOL_DEALER.CORE.APPLICATION_EVENTS a
LEFT JOIN COCO_SDLC_HOL_DEALER.CORE.DEALER_MASTER d ON a.DEALER_ID = d.DEALER_ID
WHERE d.DEALER_ID IS NULL
UNION ALL
SELECT 'orphan_contracts', COUNT(*)
FROM COCO_SDLC_HOL_DEALER.CORE.FUNDING_EVENTS f
LEFT JOIN COCO_SDLC_HOL_DEALER.CORE.DEALER_MASTER d ON f.DEALER_ID = d.DEALER_ID
WHERE d.DEALER_ID IS NULL
UNION ALL
SELECT 'orphan_servicing', COUNT(*)
FROM COCO_SDLC_HOL_DEALER.CORE.SERVICING_EVENTS s
LEFT JOIN COCO_SDLC_HOL_DEALER.CORE.FUNDING_EVENTS f ON s.CONTRACT_ID = f.CONTRACT_ID
WHERE f.CONTRACT_ID IS NULL;

-- 8. End-to-end smoke test as the role the attendee will actually use.
USE ROLE SYSADMIN;
USE WAREHOUSE HOL_DEALER360_WH;

SELECT d.TIER, COUNT(*) AS dealers, AVG(p.LOOK_TO_BOOK) AS avg_look_to_book
FROM COCO_SDLC_HOL_DEALER.CORE.DEALER_MASTER d
JOIN COCO_SDLC_HOL_DEALER.CORE.DEALER_PERFORMANCE p ON d.DEALER_ID = p.DEALER_ID
GROUP BY d.TIER
ORDER BY d.TIER;

USE ROLE ACCOUNTADMIN;
