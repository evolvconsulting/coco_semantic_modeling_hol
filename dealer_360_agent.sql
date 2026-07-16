-- LAB EXERCISE STEP: run this against your assigned attendee database, not the
-- master database this was drafted against.
--
-- Before running: replace every occurrence of
--   COCO_SDLC_HOL_DEALER_MASTER
-- with your assigned database name, e.g.
--   COCO_SDLC_HOL_DEALER_NN
--
-- ALSO: replace USE ROLE SYSADMIN below with your own assigned role, e.g.
--   USE ROLE HOL_ROLE_NN;
-- (You are logged in as HOL_USER_NN with default role HOL_ROLE_NN, not SYSADMIN.)
--
-- Prerequisite: DEALER_360_SEMANTIC_VIEW must already exist in your database
-- (completed in the semantic view step) before running this.
--
-- This single CREATE AGENT statement does three things at once:
--   1. Creates the agent object (DEALER_360_AGENT)
--   2. Declares a Cortex Analyst tool on it (query_dealer_360)
--   3. Binds that tool to your semantic view via tool_resources
-- There is no separate "add tool" step required.

USE ROLE SYSADMIN;   -- <-- substitute your assigned role, e.g. HOL_ROLE_NN
USE DATABASE COCO_SDLC_HOL_DEALER_MASTER;   -- <-- substitute your assigned DB
USE SCHEMA CORE;

CREATE OR REPLACE AGENT DEALER_360_AGENT
  COMMENT = 'Dealer 360 HOL agent: answers questions about dealer performance, applications, funding, and servicing.'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: "Answer concisely. When asked about dealer performance trends, cite specific numbers and time periods."
    orchestration: "For any question about applications, funding, servicing, dealer performance, look-to-book, funding velocity, exception rate, or application volume, use the query_dealer_360 tool."
    sample_questions:
      - question: "Which dealer's look-to-book rate has declined the most over the last three months?"
      - question: "Show me funding velocity by month for dealer D4471."
      - question: "What is the average exception rate for D4471 in June?"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "query_dealer_360"
        description: "Query the Dealer 360 semantic view for application, funding, servicing, and dealer performance data."

  tool_resources:
    query_dealer_360:
      semantic_view: "COCO_SDLC_HOL_DEALER_MASTER.CORE.DEALER_360_SEMANTIC_VIEW"
      execution_environment:
        type: "warehouse"
        warehouse: "COMPUTE_WH"
        query_timeout: 299
  $$;
