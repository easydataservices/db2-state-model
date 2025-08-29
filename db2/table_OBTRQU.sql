--------------------------------------------------------------------------------------------------------------------------------
-- File:        table_OBTRQU.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE obtrqu
(
  object_id BIGINT NOT NULL,
  transition_code VARCHAR(20) NOT NULL,
  voting_from_transition_id BIGINT NOT NULL
)
  ORGANIZE BY ROW
  IN data_obtrqu INDEX IN index_obtrqu
  COMPRESS YES;

CREATE ALIAS object_transition_quorum FOR TABLE obtrqu;

ALTER TABLE obtrqu
ADD CONSTRAINT obtrqu_pk PRIMARY KEY (object_id, transition_code);

ALTER TABLE obtrqu
ADD CONSTRAINT obtrqu_object_fk1 FOREIGN KEY (object_id) REFERENCES object;
