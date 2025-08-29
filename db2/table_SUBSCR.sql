--------------------------------------------------------------------------------------------------------------------------------
-- File:        table_SUBSCR.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE subscr
(
  subscription_id INTEGER NOT NULL,
  object_type_id SMALLINT NOT NULL,
  transition_code VARCHAR(20),
  subscription_role VARCHAR(30) NOT NULL,
  max_result_rows SMALLINT NOT NULL DEFAULT 500,
  backtrack_limit_minutes SMALLINT NOT NULL DEFAULT 1440,
  last_transition_id BIGINT NOT NULL DEFAULT 0
)
  ORGANIZE BY ROW
  IN data_stamod INDEX IN index_stamod;

CREATE ALIAS subscription FOR TABLE subscr;

ALTER TABLE subscr
ADD CONSTRAINT subscr_pk PRIMARY KEY (subscription_id);

ALTER TABLE subscr
ADD CONSTRAINT subscr_objtyp_fk1 FOREIGN KEY (object_type_id) REFERENCES objtyp;

ALTER TABLE subscr
ADD CONSTRAINT subscr_statra_fk1 FOREIGN KEY (object_type_id, transition_code) REFERENCES statra;

ALTER TABLE subscr
ADD CONSTRAINT subscr_c1 CHECK (max_result_rows > 0);

ALTER TABLE subscr
ADD CONSTRAINT subscr_c2 CHECK (backtrack_limit_minutes > 0);
