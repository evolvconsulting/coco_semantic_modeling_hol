-- LAB EXERCISE STEP: run this against your assigned attendee database, not the
-- master database this was drafted against.
--
-- Before running: replace every occurrence of
--   COCO_SDLC_HOL_DEALER_MASTER
-- with your assigned database name, e.g.
--   COCO_SDLC_HOL_DEALER_NN
--
-- You can ask Coco to do this substitution for you if you'd rather not do a manual
-- find/replace.)
--
-- ALSO: replace USE ROLE SYSADMIN below with your own assigned role, e.g.
--   USE ROLE HOL_ROLE_NN;
-- (You are logged in as HOL_USER_NN with default role HOL_ROLE_NN, not SYSADMIN.)

USE ROLE SYSADMIN;   -- <-- substitute your assigned role, e.g. HOL_ROLE_NN
USE DATABASE COCO_SDLC_HOL_DEALER_MASTER;   -- <-- substitute your assigned DB
USE SCHEMA CORE;

CREATE OR REPLACE SEMANTIC VIEW DEALER_360_SEMANTIC_VIEW

  TABLES (
    DEALER_MASTER AS COCO_SDLC_HOL_DEALER_MASTER.CORE.DEALER_MASTER
      PRIMARY KEY (DEALER_ID)
      COMMENT = 'One row per dealer; with territory, tier, and relationship manager assignment. This is the anchor table other event tables join back to.',

    APPLICATION_EVENTS AS COCO_SDLC_HOL_DEALER_MASTER.CORE.APPLICATION_EVENTS
      PRIMARY KEY (APPLICATION_ID)
      COMMENT = 'One row per credit application submitted at a dealer. This is the top of the funnel and feeds into FUNDING_EVENTS for applications with DECISION = Booked.',

    DEALER_PERFORMANCE AS COCO_SDLC_HOL_DEALER_MASTER.CORE.DEALER_PERFORMANCE
      PRIMARY KEY (DEALER_ID, PERIOD)
      COMMENT = 'Monthly performance rollup per dealer. Pre-aggregated metrics used to score and compare dealers against their tiers peer baseline.',

    FUNDING_EVENTS AS COCO_SDLC_HOL_DEALER_MASTER.CORE.FUNDING_EVENTS
      PRIMARY KEY (CONTRACT_ID)
      COMMENT = 'One row per booked contract, applications with DECISION = Booked that proceeded to contract. Tracks the funding process and any documentation exceptions that delay it. Feeds into SERVICING_EVENTS once funded.',

    SERVICING_EVENTS AS COCO_SDLC_HOL_DEALER_MASTER.CORE.SERVICING_EVENTS
      PRIMARY KEY (LOAN_ID)
      COMMENT = 'Payment/servicing events for funded loans. One row per payment period observed for a loan.'
  )

  RELATIONSHIPS (
    APPLICATION_EVENTS_TO_DEALER_MASTER AS
      APPLICATION_EVENTS (DEALER_ID) REFERENCES DEALER_MASTER (DEALER_ID),

    DEALER_PERFORMANCE_TO_DEALER_MASTER AS
      DEALER_PERFORMANCE (DEALER_ID) REFERENCES DEALER_MASTER (DEALER_ID),

    FUNDING_EVENTS_TO_APPLICATION_EVENTS AS
      FUNDING_EVENTS (APPLICATION_ID) REFERENCES APPLICATION_EVENTS (APPLICATION_ID),

    SERVICING_EVENTS_TO_FUNDING_EVENTS AS
      SERVICING_EVENTS (CONTRACT_ID) REFERENCES FUNDING_EVENTS (CONTRACT_ID)
  )

  FACTS (
    DEALER_MASTER.LATITUDE AS LATITUDE
      COMMENT = 'Dealer location latitude used for mapping.',
    DEALER_MASTER.LONGITUDE AS LONGITUDE
      COMMENT = 'Dealer location longitude used for mapping.',

    DEALER_PERFORMANCE.LOOK_TO_BOOK AS LOOK_TO_BOOK
      COMMENT = 'Share of applications that convert to a booked/funded contract in the period. Primary conversion-rate metric; declines when credit mix shifts toward riskier tiers or documentation issues rise.',
    DEALER_PERFORMANCE.FUNDING_VELOCITY AS FUNDING_VELOCITY
      COMMENT = 'Average number of days from contract signing to funding for contracts in the period. Rises when the documentation exception backlog grows.',
    DEALER_PERFORMANCE.CHARGE_OFF_CONTRIBUTION AS CHARGE_OFF_CONTRIBUTION
      COMMENT = 'This dealers charge-off rate for the period, as a percentage.',
    DEALER_PERFORMANCE.EXCEPTION_RATE AS EXCEPTION_RATE
      COMMENT = 'Share of contracts in the period held up by a documentation exception as a percentage.'
  )

  DIMENSIONS (
    DEALER_MASTER.DEALER_ID AS DEALER_ID
      COMMENT = 'Unique dealer identifier. Primary key.',
    DEALER_MASTER.DEALER_NAME AS DEALER_NAME
      COMMENT = 'Dealership name as shown to customers, such as "AutoNation USA Plano".',
    DEALER_MASTER.TIER AS TIER
      COMMENT = 'Dealer volume/tier classification: 1 (700+ apps/quarter, highest volume), 2 (300-360 apps/quarter), or 3 (lower volume). Used to select the correct peer baseline when judging performance.',
    DEALER_MASTER.TERRITORY AS TERRITORY
      COMMENT = 'Sales territory/region the dealer belongs to, such as "North DFW".',
    DEALER_MASTER.RM_NAME AS RM_NAME
      COMMENT = 'Name of the relationship manager assigned to this dealer.',

    APPLICATION_EVENTS.APPLICATION_ID AS APPLICATION_ID
      COMMENT = 'Unique application identifier. Primary key.',
    APPLICATION_EVENTS.DEALER_ID AS DEALER_ID
      COMMENT = 'Dealer where the application was submitted. References DEALER_MASTER.',
    APPLICATION_EVENTS.REQUESTED_AMOUNT AS REQUESTED_AMOUNT
      COMMENT = 'Loan amount requested on the application, in dollars.',
    APPLICATION_EVENTS.REQUESTED_TERM AS REQUESTED_TERM
      COMMENT = 'Loan term requested, in months.',
    APPLICATION_EVENTS.CREDIT_TIER AS CREDIT_TIER
      COMMENT = 'Applicant credit tier at time of application: Prime, Near_Prime, or Subprime. Riskier tiers correlate with higher decline rates and more downstream documentation exceptions.',
    APPLICATION_EVENTS.DECISION AS DECISION
      COMMENT = 'Outcome of the application with three distinct, mutually exclusive states: Approved, aka credit was approved, but the deal did not book here, Declined, or Booked meaning it was approved and this lender actually funded the contract.',
    APPLICATION_EVENTS.APP_DATE AS APP_DATE
      COMMENT = 'Date the application was submitted.',

    DEALER_PERFORMANCE.DEALER_ID AS DEALER_ID
      COMMENT = 'Dealer this rollup applies to. References DEALER_MASTER.',
    DEALER_PERFORMANCE.VOLUME AS VOLUME
      COMMENT = 'Number of applications submitted at this dealer in the period.',
    DEALER_PERFORMANCE.PERIOD AS PERIOD
      COMMENT = 'First day of the rollup month.',

    FUNDING_EVENTS.CONTRACT_ID AS CONTRACT_ID
      COMMENT = 'Unique contract identifier. Primary key.',
    FUNDING_EVENTS.APPLICATION_ID AS APPLICATION_ID
      COMMENT = 'The application this contract originated from. References APPLICATION_EVENTS.',
    FUNDING_EVENTS.DEALER_ID AS DEALER_ID
      COMMENT = 'Dealer that booked the contract. References DEALER_MASTER.',
    FUNDING_EVENTS.EXCEPTION_FLAG AS EXCEPTION_FLAG
      COMMENT = 'Whether this contract was held up by a documentation exception.',
    FUNDING_EVENTS.EXCEPTION_TYPE AS EXCEPTION_TYPE
      COMMENT = 'Type of documentation exception, if any: Income_Verification means income docs missing or insufficient, Proof_Of_Residence means the address docs missing or not matching the application, Document_Error means the documents wrong, expired, or inconsistent, or None means no exception.',
    FUNDING_EVENTS.CONTRACT_DATE AS CONTRACT_DATE
      COMMENT = 'Date the contract was signed.',
    FUNDING_EVENTS.FUNDED_DATE AS FUNDED_DATE
      COMMENT = 'Date the contract was funded. Null if still in transit / not yet funded.',

    SERVICING_EVENTS.LOAN_ID AS LOAN_ID
      COMMENT = 'Unique servicing record identifier. Primary key.',
    SERVICING_EVENTS.CONTRACT_ID AS CONTRACT_ID
      COMMENT = 'The funded contract this servicing record belongs to. References FUNDING_EVENTS.',
    SERVICING_EVENTS.DEALER_ID AS DEALER_ID
      COMMENT = 'Dealer that originated the underlying contract. References DEALER_MASTER.',
    SERVICING_EVENTS.DPD_STATUS AS DPD_STATUS
      COMMENT = 'Days-past-due bucket at this observation: Current, 30, 60, or 90+.',
    SERVICING_EVENTS.EPD_FLAG AS EPD_FLAG
      COMMENT = 'Early Payment Default flag, true if the loan defaulted unusually early in its life. The earliest signal of portfolio risk, often preceding a broader deterioration trend.',
    SERVICING_EVENTS.PAYMENT_EVENT_DATE AS PAYMENT_EVENT_DATE
      COMMENT = 'Date of this payment/servicing observation.'
  )

  METRICS (
    DEALER_PERFORMANCE.AVG_LOOK_TO_BOOK AS AVG(LOOK_TO_BOOK)
      WITH SYNONYMS ('look to book rate', 'conversion rate')
      COMMENT = 'Average share of applications that convert to a booked/funded contract, across the selected period(s) and grain.',

    DEALER_PERFORMANCE.AVG_FUNDING_VELOCITY AS AVG(FUNDING_VELOCITY)
      WITH SYNONYMS ('funding speed', 'days to fund')
      COMMENT = 'Average number of days from contract signing to funding, across the selected period(s) and grain.',

    DEALER_PERFORMANCE.AVG_EXCEPTION_RATE AS AVG(EXCEPTION_RATE)
      WITH SYNONYMS ('documentation exception rate', 'stipulation rate')
      COMMENT = 'Average share of contracts held up by a documentation exception, across the selected period(s) and grain.',

    DEALER_PERFORMANCE.APPLICATION_VOLUME AS SUM(VOLUME)
      WITH SYNONYMS ('application rate', 'number of applications', 'app volume')
      COMMENT = 'Total number of applications submitted, across the selected period(s) and grain.'
  )

  COMMENT = 'Dealer 360 auto-lending funnel: applications, funding, servicing, and dealer performance rollups';
