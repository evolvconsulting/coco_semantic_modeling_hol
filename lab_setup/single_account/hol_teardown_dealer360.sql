-- Dealer 360 HOL — SINGLE ACCOUNT teardown
--
-- Drops everything hol_setup_dealer360.sql created. Also the reset path: run
-- this, then re-run the setup script for a clean lab environment.
--
-- Drops the HOL_PARTICIPANT role but NOT the participant's user — that user is
-- provisioned and owned by DataOps.live, not by this lab.

USE ROLE SYSADMIN;

DROP DATABASE IF EXISTS HOL_DEALER360;

USE ROLE ACCOUNTADMIN;

DROP ROLE IF EXISTS HOL_PARTICIPANT;

DROP API INTEGRATION IF EXISTS HOL_GIT_API_INTEGRATION;

DROP WAREHOUSE IF EXISTS HOL_DEALER360_WH;

-- The setup script also changes an account-level parameter. Uncomment to
-- restore the default if the account is used for anything beyond this lab.
-- ALTER ACCOUNT UNSET CORTEX_ENABLED_CROSS_REGION;
