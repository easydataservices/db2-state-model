--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_HAS_STATE.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE model_info
ADD FUNCTION has_state(p_model_states INTEGER, p_model_id INTEGER, p_state_code VARCHAR(20)) RETURNS BOOLEAN
BEGIN
  DECLARE v_bit_index SMALLINT;

  -- Look up bit index for specified model state.
  SET v_bit_index =
    (
      SELECT bit_index FROM model_state WHERE model_id = p_model_id AND state_code = p_state_code WITH CS
    );

  -- Signal an exception when a bit index is not found.
  IF v_bit_index IS NULL THEN
    SIGNAL SQLSTATE 'SM001' SET MESSAGE_TEXT = 'Illegal P_STATE_CODE value for specified model';
  END IF;

  -- Calculate and return result.
  CASE BITAND(POWER(2, v_bit_index), p_model_states)
    WHEN 0 THEN RETURN FALSE;
    WHEN NULL THEN RETURN NULL;
    ELSE RETURN TRUE;
  END CASE;
END@
