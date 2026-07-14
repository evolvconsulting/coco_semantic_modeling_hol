-- SECTION 3b: Git Repository Access for the Dealer 360 seed data

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION HOL_GIT_API_INTEGRATION
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/evolvconsulting')
    ENABLED = TRUE;

USE ROLE ATTENDEE_ROLE;
USE DATABASE COCO_SDLC_HOL_DEALER_MASTER;
USE SCHEMA CORE;

-- Making this fully qualified so it never depends on the current worksheet session context
CREATE OR REPLACE GIT REPOSITORY COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_GIT_REPO
    API_INTEGRATION = HOL_GIT_API_INTEGRATION
    ORIGIN = 'https://github.com/evolvconsulting/coco_semantic_modeling_hol.git';

ALTER GIT REPOSITORY COCO_SDLC_HOL_DEALER_MASTER.CORE.HOL_GIT_REPO FETCH;
