--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_IS_COMMITTED.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

-- Return boolean indicating whether the specified transition is committed data.
ALTER MODULE subscription
ADD FUNCTION is_committed(p_transition_id BIGINT) RETURNS BOOLEAN
BEGIN
  DECLARE v_object_id BIGINT;
  DECLARE v_last_change_transition_id BIGINT;

  SET v_object_id = (SELECT object_id FROM object_state_transition WHERE transition_id = p_transition_id WITH UR);
  SET v_last_change_transition_id = (SELECT last_change_transition_id FROM object WHERE object_id = v_object_id WITH CS);
  IF v_last_change_transition_id >= p_transition_id THEN
    RETURN TRUE;
  END IF;
  RETURN FALSE;
END@
