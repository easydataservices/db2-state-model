--------------------------------------------------------------------------------------------------------------------------------
-- File:        table_MODSTA.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE modsta
(
  model_id INTEGER NOT NULL,
  object_type_id SMALLINT NOT NULL,
  bit_index SMALLINT NOT NULL,
  state_code VARCHAR(20) NOT NULL
)
  ORGANIZE BY ROW
  IN data_stamod INDEX IN index_stamod;

CREATE ALIAS model_state FOR TABLE modsta;

ALTER TABLE modsta
ADD CONSTRAINT modsta_pk PRIMARY KEY (model_id, bit_index);

ALTER TABLE modsta
ADD CONSTRAINT modsta_uk1 UNIQUE (model_id, state_code);

ALTER TABLE modsta
ADD CONSTRAINT modsta_uk2 UNIQUE (object_type_id, bit_index);

ALTER TABLE modsta
ADD CONSTRAINT modsta_modelz_fk1 FOREIGN KEY (object_type_id, model_id) REFERENCES modelz(object_type_id, model_id);

ALTER TABLE modsta
ADD CONSTRAINT modsta_c1 CHECK (bit_index BETWEEN 0 AND 30);
