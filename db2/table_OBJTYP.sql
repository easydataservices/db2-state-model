--------------------------------------------------------------------------------------------------------------------------------
-- File:        table_OBJTYP.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE objtyp
(
  object_type_id SMALLINT NOT NULL,
  type_name VARCHAR(30) NOT NULL,
  owner VARCHAR(20) NOT NULL,
  default_model_states INTEGER NOT NULL DEFAULT 1,
  creator_role VARCHAR(30) NOT NULL,
  viewer_role VARCHAR(30) NOT NULL,
  json_viewer_role VARCHAR(30) NOT NULL
)
  ORGANIZE BY ROW
  IN data_stamod INDEX IN index_stamod;

CREATE ALIAS object_type FOR TABLE objtyp;

ALTER TABLE objtyp
ADD CONSTRAINT objtyp_pk PRIMARY KEY (object_type_id);
