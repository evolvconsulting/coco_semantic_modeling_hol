-- Dealer 360 HOL — bind the participant's user to HOL_PARTICIPANT
--
-- REQUIRED STEP. hol_setup_dealer360.sql creates and grants the HOL_PARTICIPANT
-- role but binds it to nobody, because the participant's user is provisioned
-- separately by DataOps.live and its name is not known at setup time.
--
-- Run this once per account, as ACCOUNTADMIN, after DataOps.live has created the
-- user. Until it runs, the participant signs in under their lower-privilege
-- default role with no warehouse, no database, and no Cortex access.
--
-- Not fatal, but do not skip it. The DataOps.live user also carries ACCOUNTADMIN,
-- so a participant can elevate and reach the lab data that way — but that means
-- running the whole lab as ACCOUNTADMIN, and it costs room time to talk someone
-- through it. Binding ahead of time is the difference between "it just works"
-- and a live-troubleshooting detour.
--
-- Set the username below, then run the whole file.

USE ROLE ACCOUNTADMIN;

SET participant_user = 'REPLACE_WITH_DATAOPS_USERNAME';

GRANT ROLE HOL_PARTICIPANT TO USER IDENTIFIER($participant_user);

-- Defaults matter more under CoCo Desktop than they did under the CLI: the
-- onboarding wizard asks for account, username, and auth method, but never for
-- role, warehouse, or database. Setting them here means the participant lands in
-- a working session instead of having to fix it from the connection dropdown.
--
-- CAUTION: if DataOps.live manages this user through SOLE, SOLE is declarative
-- and converges the user to its project config — a later SOLE run can silently
-- revert these three defaults. Either confirm no SOLE run happens between this
-- script and lab day, or ask DataOps.live to set the defaults in their config
-- instead (which requires HOL_PARTICIPANT to exist before their run). The GRANT
-- above is not at risk; only these defaults are.
--
-- Recovery if that happens: the participant picks HOL_PARTICIPANT, the warehouse,
-- and the database from CoCo Desktop's connection dropdown. Everything still
-- works — the grant survives — they just have to set it by hand.
ALTER USER IDENTIFIER($participant_user) SET
    DEFAULT_ROLE = HOL_PARTICIPANT
    DEFAULT_WAREHOUSE = HOL_DEALER360_WH
    DEFAULT_NAMESPACE = HOL_DEALER360.CORE;

-- Confirm. Expect DEFAULT_ROLE = HOL_PARTICIPANT and the warehouse/namespace above.
DESCRIBE USER IDENTIFIER($participant_user);

SHOW GRANTS TO USER IDENTIFIER($participant_user);
