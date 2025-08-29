--------------------------------------------------------------------------------------------------------------------------------
-- File:        table_OBSTTR.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE obsttr
(
  object_id BIGINT NOT NULL,
  transition_id BIGINT NOT NULL,
  is_quorate BOOLEAN NOT NULL DEFAULT TRUE,
  from_states INTEGER NOT NULL,
  to_states INTEGER NOT NULL,
  object_type_id SMALLINT NOT NULL,
  transition_code VARCHAR(20) NOT NULL,
  transition_utc_ts TIMESTAMP(3) NOT NULL,
  transition_db_user VARCHAR(30) NOT NULL,
  transition_client_user VARCHAR(30),
  transition_json VARCHAR(2000) NOT NULL DEFAULT '{}'
)
  ORGANIZE BY ROW
  IN data_obsttr INDEX IN index_obsttr
  COMPRESS YES;

CREATE ALIAS object_state_transition FOR TABLE obsttr;

ALTER TABLE obsttr
ADD CONSTRAINT obsttr_pk PRIMARY KEY (object_id, transition_id);

CREATE UNIQUE INDEX obsttr_uk1 ON obsttr(transition_id) INCLUDE (object_type_id);

ALTER TABLE obsttr
ADD CONSTRAINT obsttr_uk1 UNIQUE (transition_id);

ALTER TABLE obsttr
ADD CONSTRAINT obsttr_object_fk1 FOREIGN KEY (object_id) REFERENCES object;

ALTER TABLE obsttr
ADD CONSTRAINT obsttr_statra_fk1 FOREIGN KEY (object_type_id, transition_code) REFERENCES statra;

CREATE UNIQUE INDEX obsttr_ix1 ON obsttr(object_type_id, transition_id) INCLUDE (transition_utc_ts);

CREATE UNIQUE INDEX obsttr_ix2 ON obsttr(object_type_id, transition_code, transition_id) INCLUDE (transition_utc_ts);
