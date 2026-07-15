USE ROLE ACCOUNTADMIN;

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

DROP DATABASE IF EXISTS COCO_SDLC_HOL_DEALER_MASTER;

DROP API INTEGRATION IF EXISTS HOL_GIT_API_INTEGRATION;

DROP WAREHOUSE IF EXISTS HOL_DEALER360_WH;
