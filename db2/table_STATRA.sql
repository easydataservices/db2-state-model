--------------------------------------------------------------------------------------------------------------------------------
-- File:        table_STATRA.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE statra
(
  object_type_id SMALLINT NOT NULL,
  transition_code VARCHAR(20) NOT NULL,
  bitand_match_rule CHAR(4) NOT NULL DEFAULT 'ALL',
  from_mask INTEGER NOT NULL DEFAULT 2147483647,
  to_mask_off INTEGER NOT NULL DEFAULT 2147483647,
  to_mask_on INTEGER NOT NULL,
  transition_role VARCHAR(30) NOT NULL,
  transition_quorum SMALLINT NOT NULL DEFAULT 1,
  description VARCHAR(60) NOT NULL
)
  ORGANIZE BY ROW
  IN data_stamod INDEX IN index_stamod;

CREATE ALIAS state_transition FOR TABLE statra;

ALTER TABLE statra
ADD CONSTRAINT statra_pk PRIMARY KEY (object_type_id, transition_code);

ALTER TABLE statra
ADD CONSTRAINT statra_objtyp_fk1 FOREIGN KEY (object_type_id) REFERENCES objtyp;

ALTER TABLE statra
ADD CONSTRAINT statra_c1 CHECK (bitand_match_rule IN ('ALL', 'NONE', 'SOME', 'ANY'));

ALTER TABLE statra
ADD CONSTRAINT statra_c2 CHECK (transition_quorum BETWEEN 1 AND 9);
