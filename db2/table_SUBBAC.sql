--------------------------------------------------------------------------------------------------------------------------------
-- File:        table_SUBBAC.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE subbac
(
  subscription_id INTEGER NOT NULL,
  start_transition_id BIGINT NOT NULL,
  end_transition_id BIGINT NOT NULL,
  backtrack_added_utc_ts TIMESTAMP(3) NOT NULL
)
  ORGANIZE BY ROW
  IN data_stamod INDEX IN index_stamod;

CREATE ALIAS subscription_backtrack FOR TABLE subbac;

CREATE UNIQUE INDEX subbac_pk ON subbac(subscription_id, start_transition_id) INCLUDE (end_transition_id);

ALTER TABLE subbac
ADD CONSTRAINT subbac_pk PRIMARY KEY (subscription_id, start_transition_id);

ALTER TABLE subbac
ADD CONSTRAINT subbac_uk1 UNIQUE (subscription_id, end_transition_id);

ALTER TABLE subbac
ADD CONSTRAINT subbac_subscr_fk1 FOREIGN KEY (subscription_id) REFERENCES subscr;

ALTER TABLE subbac
ADD CONSTRAINT subbac_c1 CHECK (start_transition_id <= end_transition_id);

ALTER TABLE subbac VOLATILE;
