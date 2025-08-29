--------------------------------------------------------------------------------------------------------------------------------
-- File:        type_SUBSCRIPTION_ROW.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE subscription
ADD TYPE subscription_row AS ROW
(
  subscription_role VARCHAR(30),
  object_type_id SMALLINT,
  transition_code VARCHAR(20),
  max_result_rows SMALLINT,
  last_transition_id BIGINT
);
