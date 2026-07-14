-- SECTION 6: Clone template into per-attendee databases

EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT {{NUM_USERS}};
BEGIN
    FOR i IN 1 TO :num_users DO
        LET suffix   VARCHAR := LPAD(i::VARCHAR, 2, '0');
        LET db_name  VARCHAR := 'COCO_SDLC_HOL_DEALER_' || :suffix;

        EXECUTE IMMEDIATE
            'CREATE DATABASE IF NOT EXISTS ' || :db_name ||
            ' CLONE COCO_SDLC_HOL_DEALER_MASTER';
    END FOR;
    RETURN 'Cloned ' || :num_users || ' attendee databases';
END;
$$;
