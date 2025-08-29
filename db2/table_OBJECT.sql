--------------------------------------------------------------------------------------------------------------------------------
-- File:        table_OBJECT.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE object
(
  object_id BIGINT NOT NULL,
  object_type_id SMALLINT NOT NULL,
  object_ref VARCHAR(60) NOT NULL,
  model_states INTEGER NOT NULL DEFAULT 0,
  initial_transition_id BIGINT NOT NULL DEFAULT 0,
  last_change_transition_id BIGINT NOT NULL DEFAULT 0
)
  ORGANIZE BY ROW
  IN data_object INDEX IN index_object
  COMPRESS YES;

CREATE UNIQUE INDEX object_pk ON object(object_id) INCLUDE (model_states, last_change_transition_id);

ALTER TABLE object
ADD CONSTRAINT object_pk PRIMARY KEY (object_id);

ALTER TABLE object
ADD CONSTRAINT object_uk1 UNIQUE (object_type_id, object_ref);

ALTER TABLE object
ADD CONSTRAINT object_objtyp_fk1 FOREIGN KEY (object_type_id) REFERENCES objtyp;

