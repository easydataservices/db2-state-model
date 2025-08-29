--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_IS_DATA_MISSING.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

-- Return boolean indicating whether the specified transition range may contain missing data for the specified object type.
ALTER MODULE subscription
ADD FUNCTION is_data_missing(p_object_type_id SMALLINT, p_start_transition_id BIGINT, p_end_transition_id BIGINT)
  RETURNS BOOLEAN
BEGIN
  DECLARE v_count BIGINT;

  -- Shortcut exit for adjacent transitions (i.e. no missing data).
  IF p_end_transition_id = p_start_transition_id + 1 THEN
    RETURN FALSE;
  END IF;

  -- Count number of rows in range that are for a different object type.
  -- Uncommitted read is safe because object type is immutable and transition identifier cannot be reused after a rollback.
  SET v_count =
    (
      SELECT
        COUNT(*)
      FROM
        object_state_transition
      WHERE
        transition_id > p_start_transition_id AND transition_id < p_end_transition_id AND object_type_id != p_object_type_id
      WITH UR
    );

  -- If the number of rows counted equals the range gap then there is no missing data.
  IF v_count = p_end_transition_id - p_start_transition_id - 1 THEN
    RETURN FALSE;
  END IF;

  -- Otherwise there is possibly missing data.
  RETURN TRUE;
END@
