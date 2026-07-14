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
