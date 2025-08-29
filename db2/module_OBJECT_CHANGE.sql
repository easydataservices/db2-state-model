--------------------------------------------------------------------------------------------------------------------------------
-- File:        module_OBJECT_CHANGE.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE MODULE object_change;

-- Add a new object, returning the object id.
ALTER MODULE object_change
PUBLISH PROCEDURE add_object
(
  p_object_type_id SMALLINT,
  p_object_ref VARCHAR(60),
  p_object_json VARCHAR(2000),
  p_creation_user VARCHAR(30),
  OUT p_object_id BIGINT
);

-- Apply the specified state transition to the specified object.
ALTER MODULE object_change
PUBLISH PROCEDURE apply_transition
(
  p_object_id BIGINT,
  p_transition_code VARCHAR(20),
  p_transition_user VARCHAR(30),
  p_transition_json VARCHAR(2000),
  OUT p_transition_id BIGINT
);
