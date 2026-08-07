CREATE OR REPLACE AGENT HOL_DEALER360_MASTER.CORE.DEALER_360_AGENT
  COMMENT = 'Dealer 360 agent for natural-language Q&A over dealer applications, funding, servicing, and monthly dealer performance.'
  PROFILE = '{"display_name": "Dealer 360 Agent", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 30
      tokens: 16000

  instructions:
    response: "Respond concisely"
    orchestration: "Use the Dealer 360 Analyst tool for any question regarding the Dealer 360 data."
    sample_questions:
      - question: "Which tier 1 dealers have a look-to-book rate below their tier baseline?"
      - question: "Show funding velocity trend by month for our top 5 dealers by volume."
      - question: "Which dealers have the highest exception rate, and what's the most common exception type behind it?"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Dealer 360 Analyst"
        description: "Answers questions about dealers, credit applications, funded contracts, loan servicing, and monthly dealer performance metrics (look-to-book, funding velocity, exception rate, charge-off contribution) using the Dealer 360 semantic view."

  tool_resources:
    "Dealer 360 Analyst":
      semantic_view: "HOL_DEALER360_MASTER.CORE.DEALER_360_SEMANTIC_VIEW"
      execution_environment:
        type: "warehouse"
        warehouse: "HOL_DEALER360_WH"
  $$
;
