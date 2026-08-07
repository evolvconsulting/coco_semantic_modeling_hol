-- Dealer 360 HOL — SINGLE ACCOUNT setup
--
-- Use this variant when each attendee has their own Snowflake account.
-- The attendee runs this once, in their own account, with ACCOUNTADMIN.
--
-- Differences from the shared-account script in lab_setup/:
--   - no user provisioning loop; one HOL_PARTICIPANT role instead of HOL_ROLE_XX
--   - no MASTER database + per-attendee clones (one database, no suffix)
--   - single-cluster warehouse (no Enterprise Edition dependency)
--
-- The participant's user is provisioned separately by DataOps.live and is
-- expected to be named USER. The final block binds HOL_PARTICIPANT to it and
-- sets its session defaults. If that user does not exist yet, or is named
-- something else, only that last block fails — everything before it still
-- applies, and the block prints what to do next. Re-running the whole script
-- once the user exists is safe.
--
-- Objects created: HOL_DEALER360_WH, HOL_PARTICIPANT, HOL_DEALER360.CORE
-- (5 tables, seeded), HOL_GIT_API_INTEGRATION, and a git repository + stage used
-- to hydrate the seed data.

USE ROLE ACCOUNTADMIN;

-- Cortex cross-region inference. AWS_US assumes the attendee account is in an
-- AWS US region. Change to match the account's cloud/region — AWS_EU, AWS_APJ,
-- AZURE_US, etc. — or use ANY_REGION if attendee accounts span regions and the
-- lab data (which is synthetic) may cross regional boundaries.
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'AWS_US';

CREATE WAREHOUSE IF NOT EXISTS HOL_DEALER360_WH
    WAREHOUSE_SIZE = XSMALL
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    COMMENT = 'HOL warehouse for Dealer 360 lab — single cluster; one attendee per account so there is no concurrent load to scale out for';

GRANT USAGE ON WAREHOUSE HOL_DEALER360_WH TO ROLE SYSADMIN;

-- The role the participant connects as. Everything the lab needs is granted to
-- this role, so the DataOps.live-provisioned user only ever needs the single
-- grant at the bottom of this script.
CREATE ROLE IF NOT EXISTS HOL_PARTICIPANT
    COMMENT = 'Dealer 360 HOL — role the lab participant connects as.';

-- Keeps HOL_PARTICIPANT inside the standard hierarchy, so a facilitator holding
-- ACCOUNTADMIN or SYSADMIN inherits it and can dry-run the lab as the
-- participant would experience it.
GRANT ROLE HOL_PARTICIPANT TO ROLE SYSADMIN;

GRANT USAGE ON WAREHOUSE HOL_DEALER360_WH TO ROLE HOL_PARTICIPANT;

-- Cortex access for the connecting role. CORTEX_USER covers Cortex Analyst and
-- is granted to PUBLIC by default in most accounts, but granting it explicitly
-- keeps a freshly provisioned account from failing at the semantic-view step.
-- CoCo Desktop additionally requires COPILOT_USER, and CORTEX_AGENT_USER for
-- the agent step.
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE HOL_PARTICIPANT;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_AGENT_USER TO ROLE HOL_PARTICIPANT;
GRANT DATABASE ROLE SNOWFLAKE.COPILOT_USER TO ROLE HOL_PARTICIPANT;

CREATE OR REPLACE API INTEGRATION HOL_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/evolvconsulting')
    ENABLED = TRUE;

GRANT USAGE ON INTEGRATION HOL_GIT_API_INTEGRATION TO ROLE SYSADMIN;

USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS HOL_DEALER360
    COMMENT = 'Dealer 360 HOL lab database — hydrated from git seed data';

USE DATABASE HOL_DEALER360;
CREATE SCHEMA IF NOT EXISTS CORE;
USE SCHEMA CORE;

CREATE OR REPLACE GIT REPOSITORY HOL_DEALER360.CORE.HOL_GIT_REPO
    API_INTEGRATION = HOL_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/evolvconsulting/coco_semantic_modeling_hol.git';

ALTER GIT REPOSITORY HOL_DEALER360.CORE.HOL_GIT_REPO FETCH;

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

CREATE OR REPLACE STAGE HOL_DEALER360.CORE.HOL_SEED_STAGE
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY FILES INTO @HOL_DEALER360.CORE.HOL_SEED_STAGE
    FROM @HOL_DEALER360.CORE.HOL_GIT_REPO/branches/main/dealer_360_seed_data/;

COPY INTO DEALER_MASTER
    FROM @HOL_DEALER360.CORE.HOL_SEED_STAGE/dealer_master.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO APPLICATION_EVENTS
    FROM @HOL_DEALER360.CORE.HOL_SEED_STAGE/application_events.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO DEALER_PERFORMANCE
    FROM @HOL_DEALER360.CORE.HOL_SEED_STAGE/dealer_performance.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO FUNDING_EVENTS
    FROM @HOL_DEALER360.CORE.HOL_SEED_STAGE/funding_events.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

COPY INTO SERVICING_EVENTS
    FROM @HOL_DEALER360.CORE.HOL_SEED_STAGE/servicing_events.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"');

-- Participant access to the lab data. ALL PRIVILEGES on the schema is what lets
-- the participant CREATE the semantic view and the agent during the lab; the
-- table grants let them read the seed data.
--
-- Deliberately not granted: HOL_SEED_STAGE and HOL_GIT_REPO. Both are setup
-- plumbing — the data is already in tables by this point — and neither is
-- touched by any lab step.
GRANT ALL PRIVILEGES ON DATABASE HOL_DEALER360 TO ROLE HOL_PARTICIPANT;
GRANT ALL PRIVILEGES ON SCHEMA HOL_DEALER360.CORE TO ROLE HOL_PARTICIPANT;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA HOL_DEALER360.CORE TO ROLE HOL_PARTICIPANT;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA HOL_DEALER360.CORE TO ROLE HOL_PARTICIPANT;

USE ROLE ACCOUNTADMIN;

-- Bind the DataOps.live-provisioned user to HOL_PARTICIPANT.
--
-- USER is quoted throughout because it is both the username and a Snowflake
-- keyword — GRANT ROLE ... TO USER USER does not parse. Double quotes also make
-- the identifier case-sensitive, so this matches a user created as USER or
-- "USER", but not one created as "user". If the name turns out to differ,
-- change it in the three places below.
--
-- Wrapped so a missing user degrades to a warning instead of failing the script:
-- everything above has already been applied by this point, and the only thing
-- left is this binding. Without the handler, a facilitator sees a hard error at
-- the end of an otherwise successful run and has to work out how much of it
-- took effect.
--
-- Setting the defaults matters more under CoCo Desktop than it did under the
-- CLI: the onboarding wizard asks for account, username, and auth method, but
-- never for role, warehouse, or database. With these set, the participant lands
-- in a working session instead of fixing it from the connection dropdown.
--
-- CAUTION: if DataOps.live manages this user through SOLE, SOLE is declarative
-- and converges the user to its project config — a later SOLE run can silently
-- revert these three defaults. Either confirm no SOLE run happens between this
-- script and lab day, or ask DataOps.live to set the defaults in their config.
-- The GRANT is not at risk; only the defaults are. If they are reverted, the
-- participant can still pick the role, warehouse, and database from CoCo
-- Desktop's connection dropdown.
EXECUTE IMMEDIATE $$
BEGIN
    GRANT ROLE HOL_PARTICIPANT TO USER "USER";

    ALTER USER "USER" SET
        DEFAULT_ROLE = HOL_PARTICIPANT
        DEFAULT_WAREHOUSE = HOL_DEALER360_WH
        DEFAULT_NAMESPACE = HOL_DEALER360.CORE;

    RETURN 'Bound HOL_PARTICIPANT to user "USER" and set its default role, warehouse, and namespace.';
EXCEPTION
    WHEN OTHER THEN
        RETURN 'WARNING — everything else in this script succeeded, but the participant '
            || 'user could not be bound: ' || SQLERRM
            || ' || Confirm the DataOps.live username (SHOW USERS), correct it in the final '
            || 'block of this script, and re-run. The lab will not work until this succeeds: '
            || 'the participant would sign in with no role, warehouse, or database.';
END;
$$;
