-- Dealer 360 HOL — SINGLE ACCOUNT teardown
--
-- Drops everything hol_setup_dealer360.sql created. Also the reset path: run
-- this, then re-run the setup script for a clean lab environment.
--
-- No users or roles are dropped here — this variant never creates any.

USE ROLE SYSADMIN;

DROP DATABASE IF EXISTS COCO_SDLC_HOL_DEALER;

USE ROLE ACCOUNTADMIN;

DROP API INTEGRATION IF EXISTS HOL_GIT_API_INTEGRATION;

DROP WAREHOUSE IF EXISTS HOL_DEALER360_WH;

-- The setup script also changes an account-level parameter. Uncomment to
-- restore the default if the account is used for anything beyond this lab.
-- ALTER ACCOUNT UNSET CORTEX_ENABLED_CROSS_REGION;
