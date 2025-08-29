--------------------------------------------------------------------------------------------------------------------------------
-- File:        table_MODELZ.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE modelz
(
  model_id INTEGER NOT NULL,
  object_type_id SMALLINT NOT NULL,
  model_name VARCHAR(30) NOT NULL
)
  ORGANIZE BY ROW
  IN data_stamod INDEX IN index_stamod;

CREATE ALIAS model FOR TABLE modelz;

ALTER TABLE modelz
ADD CONSTRAINT modelz_pk PRIMARY KEY (model_id);

ALTER TABLE modelz
ADD CONSTRAINT modelz_uk1 UNIQUE (object_type_id, model_id);

ALTER TABLE modelz
ADD CONSTRAINT modelz_objtyp_fk1 FOREIGN KEY (object_type_id) REFERENCES objtyp;
