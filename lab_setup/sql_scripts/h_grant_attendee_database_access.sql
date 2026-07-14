-- SECTION 7: Grant each attendee's own database to their own role ONLY
-- (This is what enforces isolation — HOL_ROLE_<NN> is only granted
--  access to COCO_SDLC_HOL_DEALER_<NN>, never to another attendee's DB.)

USE ROLE ACCOUNTADMIN;

EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT {{NUM_USERS}};
BEGIN
    FOR i IN 1 TO :num_users DO
        LET suffix    VARCHAR := LPAD(i::VARCHAR, 2, '0');
        LET db_name   VARCHAR := 'COCO_SDLC_HOL_DEALER_' || :suffix;
        LET role_name VARCHAR := 'HOL_ROLE_' || :suffix;

        EXECUTE IMMEDIATE
            'GRANT ALL PRIVILEGES ON DATABASE ' || :db_name || ' TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE
            'GRANT ALL PRIVILEGES ON SCHEMA ' || :db_name || '.CORE TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE
            'GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA ' || :db_name || '.CORE TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE
            'GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA ' || :db_name || '.CORE TO ROLE ' || :role_name;
    END FOR;
    RETURN 'Granted isolated access for ' || :num_users || ' attendee roles';
END;
$$;
