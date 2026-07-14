-- HOL Teardown Script — Dealer 360 Hands-On Lab
-- Reverses hol_setup_dealer360.sql completely. Run as ACCOUNTADMIN.
-- Safe to re-run — every statement targets objects that may already be gone.

USE ROLE ACCOUNTADMIN;

-- SECTION 1: Drop attendee users
EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT 25;
BEGIN
    FOR i IN 1 TO :num_users DO
        LET suffix   VARCHAR := LPAD(i::VARCHAR, 2, '0');
        LET username VARCHAR := 'HOL_USER_' || :suffix;

        EXECUTE IMMEDIATE 'DROP USER IF EXISTS ' || :username;
    END FOR;
    RETURN 'Dropped ' || :num_users || ' HOL users';
END;
$$;

-- SECTION 2: Drop attendee databases (clones)
EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT 25;
BEGIN
    FOR i IN 1 TO :num_users DO
        LET suffix  VARCHAR := LPAD(i::VARCHAR, 2, '0');
        LET db_name VARCHAR := 'COCO_SDLC_HOL_DEALER_' || :suffix;

        EXECUTE IMMEDIATE 'DROP DATABASE IF EXISTS ' || :db_name;
    END FOR;
    RETURN 'Dropped ' || :num_users || ' attendee databases';
END;
$$;

-- SECTION 3: Drop attendee roles
EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT 25;
BEGIN
    FOR i IN 1 TO :num_users DO
        LET suffix    VARCHAR := LPAD(i::VARCHAR, 2, '0');
        LET role_name VARCHAR := 'HOL_ROLE_' || :suffix;

        EXECUTE IMMEDIATE 'DROP ROLE IF EXISTS ' || :role_name;
    END FOR;
    RETURN 'Dropped ' || :num_users || ' attendee roles';
END;
$$;

-- SECTION 4: Drop the template database (git repo, stage, and tables go with it)
DROP DATABASE IF EXISTS COCO_SDLC_HOL_DEALER_MASTER;

-- SECTION 5: Drop the API integration
DROP API INTEGRATION IF EXISTS HOL_GIT_API_INTEGRATION;

-- SECTION 6: Drop the warehouse
DROP WAREHOUSE IF EXISTS HOL_DEALER360_WH;

-- Note: CORTEX_ENABLED_CROSS_REGION account setting (set in hol_setup_dealer360.sql
-- Section 1) is not reverted here — it's a harmless account-level flag with no
-- per-object footprint. Leave it unless you specifically need it unset.
