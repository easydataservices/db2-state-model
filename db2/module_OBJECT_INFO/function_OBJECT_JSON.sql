--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_OBJECT_JSON.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE object_info
ADD FUNCTION object_json(p_object_id BIGINT) RETURNS VARCHAR(2000)
BEGIN
  DECLARE v_initial_transition_id BIGINT;

  SET v_initial_transition_id = (SELECT initial_transition_id FROM object WHERE object_id = p_object_id WITH CS);
  RETURN transition_json(p_object_id, v_initial_transition_id);
END@
