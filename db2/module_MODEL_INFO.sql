--------------------------------------------------------------------------------------------------------------------------------
-- File:        module_MODEL_INFO.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE MODULE model_info;

-- Return all possible model states for the specified object type.
ALTER MODULE model_info
PUBLISH FUNCTION get_all_states(p_object_type_id SMALLINT)
  RETURNS TABLE
  (
    model_id INTEGER,
    bit_index SMALLINT,
    state_code VARCHAR(20)
  );

-- Return all active model states for the specified object type and model states.
ALTER MODULE model_info
PUBLISH FUNCTION get_active_states(p_object_type_id SMALLINT, p_model_states INTEGER)
  RETURNS TABLE
  (
    model_id INTEGER,
    bit_index SMALLINT,
    state_code VARCHAR(20)
  );

-- Return boolean indicating whether or not the specied model states have the specified state code set on.
ALTER MODULE model_info
PUBLISH FUNCTION has_state(p_model_states INTEGER, p_model_id INTEGER, p_state_code VARCHAR(20)) RETURNS BOOLEAN;
