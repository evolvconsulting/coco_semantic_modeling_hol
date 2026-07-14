-- SECTION 5: Load seed data from the git repository stage
-- Load order matches FK dependency order above
--
-- NOTE: COPY INTO cannot read directly from a Git repository stage
-- ("Unsupported feature 'Copy into table from Git Repository'").
-- Materialize the CSVs into a regular internal stage first, then
-- COPY INTO from that internal stage.

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

-- Template DB is owned by ATTENDEE_ROLE (created that way in Section 3) —
-- instructor-only, never handed out to attendees.
