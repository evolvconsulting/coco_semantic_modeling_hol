-- SECTION 2: Create per-attendee roles and users

EXECUTE IMMEDIATE $$
DECLARE
    num_users  INTEGER DEFAULT {{NUM_USERS}};
    hol_pass   VARCHAR DEFAULT '{{HOL_PASSWORD}}';
BEGIN
    FOR i IN 1 TO :num_users DO
        LET suffix    VARCHAR := LPAD(i::VARCHAR, 2, '0');
        LET username  VARCHAR := 'HOL_USER_' || :suffix;
        LET role_name VARCHAR := 'HOL_ROLE_' || :suffix;

        -- Per-attendee role, inherits the shared base role
        EXECUTE IMMEDIATE
            'CREATE ROLE IF NOT EXISTS ' || :role_name;
        EXECUTE IMMEDIATE
            'GRANT ROLE ATTENDEE_ROLE TO ROLE ' || :role_name;
        EXECUTE IMMEDIATE
            'GRANT ROLE ' || :role_name || ' TO ROLE SYSADMIN';

        EXECUTE IMMEDIATE
            'CREATE USER IF NOT EXISTS ' || :username ||
            ' PASSWORD = ''' || :hol_pass || '''' ||
            ' DEFAULT_ROLE = ' || :role_name ||
            ' DEFAULT_WAREHOUSE = COMPUTE_WH' ||
            ' MUST_CHANGE_PASSWORD = FALSE' ||
            ' COMMENT = ''HOL attendee user''';

        EXECUTE IMMEDIATE
            'ALTER USER ' || :username || ' SET MINS_TO_BYPASS_MFA = 1200';

        EXECUTE IMMEDIATE
            'GRANT ROLE ' || :role_name || ' TO USER ' || :username;
    END FOR;
    RETURN 'Created ' || :num_users || ' HOL users and roles with MFA bypass';
END;
$$;
