-- Dealer 360 HOL — bind the participant's user to HOL_PARTICIPANT
--
-- REQUIRED STEP. hol_setup_dealer360.sql creates and grants the HOL_PARTICIPANT
-- role but binds it to nobody, because the participant's user is provisioned
-- separately by DataOps.live and its name is not known at setup time.
--
-- Run this once per account, as ACCOUNTADMIN, after DataOps.live has created the
-- user. Until it runs, the participant can sign in but has no warehouse, no
-- database, and no Cortex access — the lab will not work.
--
-- Set the username below, then run the whole file.

USE ROLE ACCOUNTADMIN;

SET participant_user = 'REPLACE_WITH_DATAOPS_USERNAME';

GRANT ROLE HOL_PARTICIPANT TO USER IDENTIFIER($participant_user);

-- Defaults matter more under CoCo Desktop than they did under the CLI: the
-- onboarding wizard asks for account, username, and auth method, but never for
-- role, warehouse, or database. Setting them here means the participant lands in
-- a working session instead of having to fix it from the connection dropdown.
ALTER USER IDENTIFIER($participant_user) SET
    DEFAULT_ROLE = HOL_PARTICIPANT
    DEFAULT_WAREHOUSE = HOL_DEALER360_WH
    DEFAULT_NAMESPACE = HOL_DEALER360.CORE;

-- Confirm. Expect DEFAULT_ROLE = HOL_PARTICIPANT and the warehouse/namespace above.
DESCRIBE USER IDENTIFIER($participant_user);

SHOW GRANTS TO USER IDENTIFIER($participant_user);
