-- HOL Setup Script — Dealer 360 Hands-On Lab
-- Run all sections sequentially in a Snowflake worksheet as ACCOUNTADMIN.
-- Designed to run on a FRESH lab account — all objects created from scratch.
--
-- Seed data source: https://github.com/evolvconsulting/coco_semantic_modeling_hol.git
--   Branch: main
--   Path:   dealer_360_seed_data/
--
-- ISOLATION MODEL:
--   No shared attendee role. SYSADMIN owns the template database and all
--   clones. HOL_ROLE_<NN> — one per attendee — is granted ONLY warehouse
--   usage plus exclusive access to that attendee's own cloned database.
--   Each HOL_USER_<NN>'s DEFAULT_ROLE is their own HOL_ROLE_<NN>, so they
--   cannot see or access other attendees' databases.
--
-- ATTENDEE CREDENTIALS:
--   Username : HOL_USER_01 ... HOL_USER_<NN>
--   Password : Snowflake123!
--   Database : COCO_SDLC_HOL_DEALER_01 ... COCO_SDLC_HOL_DEALER_<NN>, each user gets one
--   Template : COCO_SDLC_HOL_DEALER_MASTER The database we'll create zero copy clones of for our users

-- SECTION 1: Configuration
--
-- NUM_USERS and HOL_PASSWORD are hardcoded independently in 4 places below
-- (Snowflake scripting blocks can't read session SET variables directly).
-- If you change either value, edit ALL of these lines:
--   NUM_USERS:    24, 51, 199, 222
--   HOL_PASSWORD: 52

USE ROLE ACCOUNTADMIN;

ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';

CREATE WAREHOUSE IF NOT EXISTS HOL_DEALER360_WH
    WAREHOUSE_SIZE = XSMALL
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 4
    SCALING_POLICY = STANDARD
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'HOL warehouse for Dealer 360 lab — multi-cluster so concurrent attendee load auto-scales out instead of queueing';

-- SECTION 2: Create per-attendee roles and users

EXECUTE IMMEDIATE $$
DECLARE
    num_users  INTEGER DEFAULT 25;
    hol_pass   VARCHAR DEFAULT 'Snowflake123!';
BEGIN
    FOR i IN 1 TO :num_users DO
        LET suffix    VARCHAR := LPAD(i::VARCHAR, 2, '0');
        LET username  VARCHAR := 'HOL_USER_' || :suffix;
        LET role_name VARCHAR := 'HOL_ROLE_' || :suffix;

        -- Per-attendee role. No shared base role — grants happen individually.
        EXECUTE IMMEDIATE
            'CREATE ROLE IF NOT EXISTS ' || :role_name;
        EXECUTE IMMEDIATE
            'GRANT ROLE ' || :role_name || ' TO ROLE SYSADMIN';
        EXECUTE IMMEDIATE
            'GRANT USAGE ON WAREHOUSE HOL_DEALER360_WH TO ROLE ' || :role_name;

        EXECUTE IMMEDIATE
            'CREATE USER IF NOT EXISTS ' || :username ||
            ' PASSWORD = ''' || :hol_pass || '''' ||
            ' DEFAULT_ROLE = ' || :role_name ||
            ' DEFAULT_WAREHOUSE = HOL_DEALER360_WH' ||
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

-- SECTION 3: The Template Database, named COCO_SDLC_HOL_DEALER_MASTER
-- Owned by SYSADMIN — never granted to attendee roles.

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS COCO_SDLC_HOL_DEALER_MASTER
    COMMENT = 'Dealer 360 HOL lab template — hydrated from git seed data, cloned per attendee';

USE DATABASE COCO_SDLC_HOL_DEALER_MASTER;
CREATE SCHEMA IF NOT EXISTS CORE;
USE SCHEMA CORE;

-- SECTION 3b: Git Repository Access for the Dealer 360 seed data

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION HOL_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/evolvconsulting')
    ENABLED = TRUE;

GRANT USAGE ON INTEGRATION HOL_GIT_API_INTEGRATION TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
USE DATABASE COCO_SDLC_HOL_DEALER_MASTER;
USE SCHEMA CORE;

-- Making this fully qualified so it never depends on the current worksheet session context
CREATE OR REPLACE GIT REPOSITORY COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_GIT_REPO
    API_INTEGRATION = HOL_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/evolvconsulting/coco_semantic_modeling_hol.git';

ALTER GIT REPOSITORY COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_GIT_REPO FETCH;

-- SECTION 4: Template Tables
-- Table order respects FK dependencies: DEALER_MASTER first, then its dependents

CREATE OR REPLACE TABLE DEALER_MASTER (
    DEALER_ID    VARCHAR(16777216) NOT NULL COMMENT 'Unique dealer identifier. Primary key.',
    DEALER_NAME  VARCHAR(16777216) COMMENT 'Dealership name as shown to customers, such as "AutoNation USA Plano".',
    TIER         VARCHAR(16777216) COMMENT 'Dealer volume/tier classification: 1 (700+ apps/quarter, highest volume), 2 (300-360 apps/quarter), or 3 (lower volume). Used to select the correct peer baseline when judging performance.',
    TERRITORY    VARCHAR(16777216) COMMENT 'Sales territory/region the dealer belongs to, such as "North DFW".',
    RM_NAME      VARCHAR(16777216) COMMENT 'Name of the relationship manager assigned to this dealer.',
    LATITUDE     FLOAT COMMENT 'Dealer location latitude used for mapping.',
    LONGITUDE    FLOAT COMMENT 'Dealer location longitude used for mapping.',
    CONSTRAINT PK_DEALER_MASTER PRIMARY KEY (DEALER_ID)
)
COMMENT = 'One row per dealer; with territory, tier, and relationship manager assignment. This is the anchor table other event tables join back to.';

CREATE OR REPLACE TABLE APPLICATION_EVENTS (
    APPLICATION_ID    VARCHAR(16777216) NOT NULL COMMENT 'Unique application identifier. Primary key.',
    DEALER_ID         VARCHAR(16777216) COMMENT 'Dealer where the application was submitted. References DEALER_MASTER.',
    APP_DATE          DATE COMMENT 'Date the application was submitted.',
    REQUESTED_AMOUNT  NUMBER(38,0) COMMENT 'Loan amount requested on the application, in dollars.',
    REQUESTED_TERM    NUMBER(38,0) COMMENT 'Loan term requested, in months.',
    CREDIT_TIER       VARCHAR(16777216) COMMENT 'Applicant credit tier at time of application: Prime, Near_Prime, or Subprime. Riskier tiers correlate with higher decline rates and more downstream documentation exceptions.',
    DECISION          VARCHAR(16777216) COMMENT 'Outcome of the application with three distinct, mutually exclusive states: Approved, aka credit was approved, but the deal did not book here, Declined, or Booked meaning it was approved and this lender actually funded the contract.',
    CONSTRAINT PK_APPLICATION_EVENTS PRIMARY KEY (APPLICATION_ID),
    CONSTRAINT FK_APPLICATION_EVENTS_DEALER FOREIGN KEY (DEALER_ID) REFERENCES DEALER_MASTER(DEALER_ID)
)
COMMENT = 'One row per credit application submitted at a dealer. This is the top of the funnel and feeds into FUNDING_EVENTS for applications with DECISION = Booked.';

CREATE OR REPLACE TABLE DEALER_PERFORMANCE (
    DEALER_ID                 VARCHAR(16777216) NOT NULL COMMENT 'Dealer this rollup applies to. References DEALER_MASTER.',
    PERIOD                    DATE NOT NULL COMMENT 'First day of the rollup month.',
    VOLUME                    NUMBER(38,0) COMMENT 'Number of applications submitted at this dealer in the period.',
    LOOK_TO_BOOK              FLOAT COMMENT 'Share of applications that convert to a booked/funded contract in the period. Primary conversion-rate metric; declines when credit mix shifts toward riskier tiers or documentation issues rise.',
    FUNDING_VELOCITY          FLOAT COMMENT 'Average number of days from contract signing to funding for contracts in the period. Rises when the documentation exception backlog grows.',
    CHARGE_OFF_CONTRIBUTION   FLOAT COMMENT 'This dealers charge-off rate for the period, as a percentage.',
    EXCEPTION_RATE             FLOAT COMMENT 'Share of contracts in the period held up by a documentation exception as a percentage.',
    CONSTRAINT PK_DEALER_PERFORMANCE PRIMARY KEY (DEALER_ID, PERIOD),
    CONSTRAINT FK_DEALER_PERFORMANCE_DEALER FOREIGN KEY (DEALER_ID) REFERENCES DEALER_MASTER(DEALER_ID)
)
COMMENT = 'Monthly performance rollup per dealer. Pre-aggregated metrics used to score and compare dealers against their tiers peer baseline.';

CREATE OR REPLACE TABLE FUNDING_EVENTS (
    CONTRACT_ID      VARCHAR(16777216) NOT NULL COMMENT 'Unique contract identifier. Primary key.',
    APPLICATION_ID   VARCHAR(16777216) COMMENT 'The application this contract originated from. References APPLICATION_EVENTS.',
    DEALER_ID        VARCHAR(16777216) COMMENT 'Dealer that booked the contract. References DEALER_MASTER.',
    CONTRACT_DATE    DATE COMMENT 'Date the contract was signed.',
    FUNDED_DATE      DATE COMMENT 'Date the contract was funded. Null if still in transit / not yet funded.',
    EXCEPTION_FLAG   BOOLEAN COMMENT 'Whether this contract was held up by a documentation exception.',
    EXCEPTION_TYPE   VARCHAR(16777216) COMMENT 'Type of documentation exception, if any: Income_Verification means income docs missing or insufficient, Proof_Of_Residence means the address docs missing or not matching the application, Document_Error means the documents wrong, expired, or inconsistent, or None means no exception.',
    CONSTRAINT PK_FUNDING_EVENTS PRIMARY KEY (CONTRACT_ID),
    CONSTRAINT FK_FUNDING_EVENTS_APPLICATION FOREIGN KEY (APPLICATION_ID) REFERENCES APPLICATION_EVENTS(APPLICATION_ID),
    CONSTRAINT FK_FUNDING_EVENTS_DEALER FOREIGN KEY (DEALER_ID) REFERENCES DEALER_MASTER(DEALER_ID)
)
COMMENT = 'One row per booked contract, applications with DECISION = Booked that proceeded to contract. Tracks the funding process and any documentation exceptions that delay it. Feeds into SERVICING_EVENTS once funded.';

CREATE OR REPLACE TABLE SERVICING_EVENTS (
    LOAN_ID              VARCHAR(16777216) NOT NULL COMMENT 'Unique servicing record identifier. Primary key.',
    CONTRACT_ID          VARCHAR(16777216) COMMENT 'The funded contract this servicing record belongs to. References FUNDING_EVENTS.',
    DEALER_ID            VARCHAR(16777216) COMMENT 'Dealer that originated the underlying contract. References DEALER_MASTER.',
    PAYMENT_EVENT_DATE   DATE COMMENT 'Date of this payment/servicing observation.',
    DPD_STATUS           VARCHAR(16777216) COMMENT 'Days-past-due bucket at this observation: Current, 30, 60, or 90+.',
    EPD_FLAG             BOOLEAN COMMENT 'Early Payment Default flag, true if the loan defaulted unusually early in its life. The earliest signal of portfolio risk, often preceding a broader deterioration trend.',
    CONSTRAINT PK_SERVICING_EVENTS PRIMARY KEY (LOAN_ID),
    CONSTRAINT FK_SERVICING_EVENTS_CONTRACT FOREIGN KEY (CONTRACT_ID) REFERENCES FUNDING_EVENTS(CONTRACT_ID),
    CONSTRAINT FK_SERVICING_EVENTS_DEALER FOREIGN KEY (DEALER_ID) REFERENCES DEALER_MASTER(DEALER_ID)
)
COMMENT = 'Payment/servicing events for funded loans. One row per payment period observed for a loan.';

-- SECTION 5: Load seed data from the git repository stage
-- Load order matches FK dependency order above

CREATE OR REPLACE STAGE COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_SEED_STAGE
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY FILES INTO @COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_SEED_STAGE
    FROM @COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_GIT_REPO/branches/main/dealer_360_seed_data/;

COPY INTO DEALER_MASTER
    FROM @COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_SEED_STAGE/dealer_master.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO APPLICATION_EVENTS
    FROM @COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_SEED_STAGE/application_events.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO DEALER_PERFORMANCE
    FROM @COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_SEED_STAGE/dealer_performance.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO FUNDING_EVENTS
    FROM @COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_SEED_STAGE/funding_events.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO SERVICING_EVENTS
    FROM @COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_SEED_STAGE/servicing_events.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-- Template DB is owned by SYSADMIN (created that way in Section 3) —
-- instructor-only, never handed out to attendees.

-- ============================================================
-- SECTION 6: Clone template into per-attendee databases
-- ============================================================
EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT 25;
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

-- ============================================================
-- SECTION 7: Grant each attendee's own database to their own role ONLY
-- (This is what enforces isolation — HOL_ROLE_<NN> is only granted
--  access to COCO_SDLC_HOL_DEALER_<NN>, never to another attendee's DB.
--  Clones are owned by SYSADMIN, so no shared role's ownership can leak
--  access across attendees.)
-- ============================================================

EXECUTE IMMEDIATE $$
DECLARE
    num_users INTEGER DEFAULT 25;
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
