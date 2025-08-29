--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_IS_SKIPPABLE.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

-- Return boolean indicating whether or not the specified transition is assigned to another object type (hence can be skipped).
ALTER MODULE subscription
ADD FUNCTION is_skippable(p_object_type_id SMALLINT, p_transition_id BIGINT) RETURNS BOOLEAN
BEGIN
  DECLARE v_object_type_id SMALLINT;

  -- Read object type of specified transition.
  -- Uncommitted read is safe because object type is immutable and transition identifier cannot be reused after a rollback.
  SET v_object_type_id = (SELECT object_type_id FROM object_state_transition WHERE transition_id = p_transition_id WITH UR);
  
  -- If the transition exists and its object type does not match the specified object type then return true (skippable).
  IF v_object_type_id != p_object_type_id THEN
    RETURN TRUE;
  END IF;

  -- Otherwise return false (the row cannot be safely skipped).
  RETURN FALSE;
END@
