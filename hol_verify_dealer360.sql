-- HOL Verification Script — Dealer 360 Hands-On Lab
-- Run after hol_setup_dealer360.sql to confirm the lab environment is correct.
-- Run as ACCOUNTADMIN.

USE ROLE ACCOUNTADMIN;

-- CHECK 1: Users exist, with expected default role / warehouse, and enabled
SHOW USERS LIKE 'HOL_USER_%';
SELECT
    "name" AS username,
    "default_role",
    "default_warehouse",
    "disabled",
    "mins_to_bypass_mfa"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
ORDER BY username;

-- Expect 25 rows, disabled = false, default_role = HOL_ROLE_<NN> matching the suffix
SELECT COUNT(*) AS user_count FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- CHECK 2: Roles exist, and are correctly scoped
SHOW ROLES LIKE 'HOL_ROLE_%';
SELECT COUNT(*) AS role_count FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
-- Expect 25 rows

SHOW GRANTS TO ROLE HOL_ROLE_01;
-- Expect: USAGE on HOL_DEALER360_WH, plus ALL PRIVILEGES on COCO_SDLC_HOL_DEALER_01
-- (DB/schema/tables) only — nothing on any other attendee's database

-- CHECK 3: Template database and its tables are populated
SELECT 'DEALER_MASTER' AS table_name, COUNT(*) AS row_count FROM COCO_SDLC_HOL_DEALER_MASTER.CORE.DEALER_MASTER
UNION ALL
SELECT 'APPLICATION_EVENTS', COUNT(*) FROM COCO_SDLC_HOL_DEALER_MASTER.CORE.APPLICATION_EVENTS
UNION ALL
SELECT 'DEALER_PERFORMANCE', COUNT(*) FROM COCO_SDLC_HOL_DEALER_MASTER.CORE.DEALER_PERFORMANCE
UNION ALL
SELECT 'FUNDING_EVENTS', COUNT(*) FROM COCO_SDLC_HOL_DEALER_MASTER.CORE.FUNDING_EVENTS
UNION ALL
SELECT 'SERVICING_EVENTS', COUNT(*) FROM COCO_SDLC_HOL_DEALER_MASTER.CORE.SERVICING_EVENTS;
-- Expect all 5 row_counts > 0

-- CHECK 4: Git repo fetched correctly
SHOW GIT REPOSITORIES LIKE 'HOL_GIT_REPO';
LIST @COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_GIT_REPO/branches/main/dealer_360_seed_data/;
-- Expect the 5 seed CSVs listed

-- CHECK 5: All 25 attendee databases exist and are zero-copy clones of the template
SHOW DATABASES LIKE 'COCO_SDLC_HOL_DEALER_%';
SELECT "name" AS db_name, "created_on"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" != 'COCO_SDLC_HOL_DEALER_MASTER'
ORDER BY db_name;
-- Expect 25 rows, created_on clustered around the same run timestamp

SELECT COUNT(*) AS clone_count
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- Confirm clone lineage explicitly via account usage (clone_group_id shared with the template)
-- Note: ACCOUNT_USAGE views can lag up to 45 min after object creation
SELECT database_name, database_id, clone_group_id, created
FROM SNOWFLAKE.ACCOUNT_USAGE.DATABASES
WHERE database_name ILIKE 'COCO_SDLC_HOL_DEALER%'
  AND deleted IS NULL
ORDER BY database_name;
-- Expect all rows to share one clone_group_id

-- Spot-check row counts on one clone match the template (clones share physical micro-partitions)
SELECT 'DEALER_MASTER' AS table_name, COUNT(*) AS row_count FROM COCO_SDLC_HOL_DEALER_01.CORE.DEALER_MASTER
UNION ALL
SELECT 'APPLICATION_EVENTS', COUNT(*) FROM COCO_SDLC_HOL_DEALER_01.CORE.APPLICATION_EVENTS
UNION ALL
SELECT 'FUNDING_EVENTS', COUNT(*) FROM COCO_SDLC_HOL_DEALER_01.CORE.FUNDING_EVENTS
UNION ALL
SELECT 'SERVICING_EVENTS', COUNT(*) FROM COCO_SDLC_HOL_DEALER_01.CORE.SERVICING_EVENTS
UNION ALL
SELECT 'DEALER_PERFORMANCE', COUNT(*) FROM COCO_SDLC_HOL_DEALER_01.CORE.DEALER_PERFORMANCE;
-- Expect these to match CHECK 3's counts exactly

-- CHECK 6: Isolation — HOL_ROLE_01 can see its own DB but not another attendee's
USE ROLE SYSADMIN;
USE ROLE HOL_ROLE_01;

SHOW DATABASES LIKE 'COCO_SDLC_HOL_DEALER_%';
-- Expect: only COCO_SDLC_HOL_DEALER_01 visible, not _02, _03, ... or MASTER —
-- with no shared role granting CREATE DATABASE, this should now genuinely
-- reflect what HOL_ROLE_01 can access, not just what it can enumerate

SELECT COUNT(*) FROM COCO_SDLC_HOL_DEALER_01.CORE.DEALER_MASTER;
-- Expect: success

SELECT COUNT(*) FROM COCO_SDLC_HOL_DEALER_02.CORE.DEALER_MASTER;
-- Expect: this should FAIL with an object-does-not-exist / access-denied error —
-- that failure is what confirms isolation is actually enforced

USE ROLE ACCOUNTADMIN;
