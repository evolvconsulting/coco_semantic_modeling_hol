-- Dealer 360 HOL — SINGLE ACCOUNT semantic view (reference / answer key)
--
-- Attendees build this themselves during the lab; this is what a complete
-- version looks like. Not run by hol_setup_dealer360.sql.

CREATE OR REPLACE SEMANTIC VIEW COCO_SDLC_HOL_DEALER.CORE.DEALER_360_SEMANTIC_VIEW
  TABLES (
    DEALER_MASTER AS COCO_SDLC_HOL_DEALER.CORE.DEALER_MASTER
      PRIMARY KEY (DEALER_ID)
      WITH SYNONYMS ('dealers', 'dealer master')
      COMMENT = 'One row per dealer; the anchor table every other table joins back to.',
    APPLICATION_EVENTS AS COCO_SDLC_HOL_DEALER.CORE.APPLICATION_EVENTS
      PRIMARY KEY (APPLICATION_ID)
      WITH SYNONYMS ('applications')
      COMMENT = 'Top of the funnel. One row per credit application submitted at a dealer.',
    FUNDING_EVENTS AS COCO_SDLC_HOL_DEALER.CORE.FUNDING_EVENTS
      PRIMARY KEY (CONTRACT_ID)
      WITH SYNONYMS ('contracts', 'funded deals')
      COMMENT = 'One row per booked contract (applications with DECISION = Booked that proceeded to contract).',
    SERVICING_EVENTS AS COCO_SDLC_HOL_DEALER.CORE.SERVICING_EVENTS
      PRIMARY KEY (LOAN_ID)
      WITH SYNONYMS ('loan servicing', 'payments')
      COMMENT = 'One row per payment/servicing observation for a funded loan.',
    DEALER_PERFORMANCE AS COCO_SDLC_HOL_DEALER.CORE.DEALER_PERFORMANCE
      PRIMARY KEY (DEALER_ID, PERIOD)
      WITH SYNONYMS ('dealer performance', 'monthly dealer rollup', 'dealer scorecard')
      COMMENT = 'Monthly, pre-aggregated performance rollup per dealer used to score dealers against their tier peer baseline.'
  )
  RELATIONSHIPS (
    APPLICATION_EVENTS_TO_DEALER_MASTER AS APPLICATION_EVENTS (DEALER_ID) REFERENCES DEALER_MASTER (DEALER_ID),
    FUNDING_EVENTS_TO_APPLICATION_EVENTS AS FUNDING_EVENTS (APPLICATION_ID) REFERENCES APPLICATION_EVENTS (APPLICATION_ID),
    FUNDING_EVENTS_TO_DEALER_MASTER AS FUNDING_EVENTS (DEALER_ID) REFERENCES DEALER_MASTER (DEALER_ID),
    SERVICING_EVENTS_TO_FUNDING_EVENTS AS SERVICING_EVENTS (CONTRACT_ID) REFERENCES FUNDING_EVENTS (CONTRACT_ID),
    DEALER_PERFORMANCE_TO_DEALER_MASTER AS DEALER_PERFORMANCE (DEALER_ID) REFERENCES DEALER_MASTER (DEALER_ID)
  )
  FACTS (
    APPLICATION_EVENTS.REQUESTED_AMOUNT AS REQUESTED_AMOUNT
      COMMENT = 'Loan amount requested on the application, in dollars.',
    APPLICATION_EVENTS.REQUESTED_TERM AS REQUESTED_TERM
      COMMENT = 'Loan term requested, in months.',
    FUNDING_EVENTS.DAYS_TO_FUND AS DATEDIFF('day', CONTRACT_DATE, FUNDED_DATE)
      WITH SYNONYMS ('funding velocity (raw)')
      COMMENT = 'Days from contract signing to funding for this individual contract.'
  )
  DIMENSIONS (
    DEALER_MASTER.DEALER_ID AS DEALER_ID
      COMMENT = 'Unique dealer identifier.',
    DEALER_MASTER.DEALER_NAME AS DEALER_NAME
      WITH SYNONYMS ('dealership')
      COMMENT = 'Dealership name as shown to customers.',
    DEALER_MASTER.TIER AS TIER
      WITH SYNONYMS ('dealer tier', 'volume tier')
      COMMENT = 'Dealer volume/tier classification: 1 (700+ apps/quarter, highest volume), 2 (300-360 apps/quarter), or 3 (lower volume). Used to select the correct peer baseline.',
    DEALER_MASTER.TERRITORY AS TERRITORY
      WITH SYNONYMS ('region', 'sales territory')
      COMMENT = 'Sales territory/region the dealer belongs to.',
    DEALER_MASTER.RM_NAME AS RM_NAME
      WITH SYNONYMS ('relationship manager')
      COMMENT = 'Name of the relationship manager assigned to this dealer.',
    APPLICATION_EVENTS.CREDIT_TIER AS CREDIT_TIER
      WITH SYNONYMS ('applicant credit tier', 'risk tier')
      COMMENT = 'Applicant credit tier at time of application: Prime, Near_Prime, or Subprime.',
    APPLICATION_EVENTS.DECISION AS DECISION
      WITH SYNONYMS ('application outcome')
      COMMENT = 'Outcome of the application: Approved (credit approved but booked elsewhere), Declined, or Booked (approved and funded by this lender).',
    APPLICATION_EVENTS.APP_DATE AS APP_DATE
      WITH SYNONYMS ('application date')
      COMMENT = 'Date the application was submitted.',
    FUNDING_EVENTS.EXCEPTION_TYPE AS EXCEPTION_TYPE
      WITH SYNONYMS ('stipulation type')
      COMMENT = 'Type of documentation exception, if any: Income_Verification, Proof_Of_Residence, Document_Error, or None.',
    FUNDING_EVENTS.EXCEPTION_FLAG AS EXCEPTION_FLAG
      WITH SYNONYMS ('stipulation flag')
      COMMENT = 'Whether this contract was held up by a documentation exception.',
    FUNDING_EVENTS.CONTRACT_DATE AS CONTRACT_DATE
      COMMENT = 'Date the contract was signed.',
    FUNDING_EVENTS.FUNDED_DATE AS FUNDED_DATE
      COMMENT = 'Date the contract was funded. Null if not yet funded.',
    SERVICING_EVENTS.DPD_STATUS AS DPD_STATUS
      WITH SYNONYMS ('days past due', 'delinquency status')
      COMMENT = 'Days-past-due bucket at this observation: Current, 30, 60, or 90+.',
    SERVICING_EVENTS.EPD_FLAG AS EPD_FLAG
      WITH SYNONYMS ('early payment default')
      COMMENT = 'True if the loan defaulted unusually early in its life, an early portfolio-risk signal.',
    SERVICING_EVENTS.PAYMENT_EVENT_DATE AS PAYMENT_EVENT_DATE
      COMMENT = 'Date of this payment/servicing observation.',
    DEALER_PERFORMANCE.PERIOD AS PERIOD
      WITH SYNONYMS ('month')
      COMMENT = 'First day of the rollup month.'
  )
  METRICS (
    APPLICATION_EVENTS.APPLICATION_COUNT AS COUNT(APPLICATION_EVENTS.APPLICATION_ID)
      WITH SYNONYMS ('application volume (raw)', 'number of applications')
      COMMENT = 'Raw count of applications at the application grain.',
    APPLICATION_EVENTS.BOOKED_COUNT AS SUM(IFF(APPLICATION_EVENTS.DECISION = 'Booked', 1, 0))
      WITH SYNONYMS ('booked applications')
      COMMENT = 'Count of applications that resulted in a booked/funded contract.',
    APPLICATION_EVENTS.TOTAL_REQUESTED_AMOUNT AS SUM(APPLICATION_EVENTS.REQUESTED_AMOUNT)
      COMMENT = 'Total dollar amount requested across applications.',
    FUNDING_EVENTS.CONTRACT_COUNT AS COUNT(FUNDING_EVENTS.CONTRACT_ID)
      WITH SYNONYMS ('funded contract count', 'booked deal count')
      COMMENT = 'Raw count of funded/booked contracts.',
    FUNDING_EVENTS.EXCEPTION_COUNT AS SUM(IFF(FUNDING_EVENTS.EXCEPTION_FLAG, 1, 0))
      WITH SYNONYMS ('stipulation count')
      COMMENT = 'Count of contracts held up by a documentation exception.',
    FUNDING_EVENTS.AVG_DAYS_TO_FUND AS AVG(FUNDING_EVENTS.DAYS_TO_FUND)
      WITH SYNONYMS ('average funding velocity (raw)')
      COMMENT = 'Average days from signing to funding across contracts, computed at the contract grain.',
    SERVICING_EVENTS.EPD_COUNT AS SUM(IFF(SERVICING_EVENTS.EPD_FLAG, 1, 0))
      WITH SYNONYMS ('early payment default count')
      COMMENT = 'Count of loans flagged for early payment default.',
    DEALER_PERFORMANCE.TOTAL_VOLUME AS SUM(DEALER_PERFORMANCE.VOLUME)
      WITH SYNONYMS ('application volume', 'volume')
      COMMENT = 'Total number of applications submitted, per the monthly dealer rollup. Used to group/tier dealers by scale.',
    DEALER_PERFORMANCE.AVG_LOOK_TO_BOOK AS AVG(DEALER_PERFORMANCE.LOOK_TO_BOOK)
      WITH SYNONYMS ('conversion rate', 'look-to-book')
      COMMENT = 'Average share of applications that convert to a booked/funded contract. This is the primary conversion-rate north star metric; average, never sum, a rate.',
    DEALER_PERFORMANCE.AVG_FUNDING_VELOCITY AS AVG(DEALER_PERFORMANCE.FUNDING_VELOCITY)
      WITH SYNONYMS ('funding velocity', 'days to fund')
      COMMENT = 'Average number of days from contract signing to funding. Rises when the documentation exception backlog grows.',
    DEALER_PERFORMANCE.AVG_EXCEPTION_RATE AS AVG(DEALER_PERFORMANCE.EXCEPTION_RATE)
      WITH SYNONYMS ('exception rate', 'stipulation rate')
      COMMENT = 'Average share of contracts held up by a documentation exception.',
    DEALER_PERFORMANCE.AVG_CHARGE_OFF_CONTRIBUTION AS AVG(DEALER_PERFORMANCE.CHARGE_OFF_CONTRIBUTION)
      WITH SYNONYMS ('charge-off rate', 'charge-off contribution')
      COMMENT = 'Average dealer charge-off rate for the period, as a percentage.'
  )
  COMMENT = 'Dealer 360: application-to-servicing lifecycle for dealer credit applications, funded contracts, and loan servicing, plus a pre-aggregated monthly dealer performance scorecard.'
;
