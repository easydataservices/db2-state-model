--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_IS_FROM_STATES_MATCH.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

-- Return TRUE if the model states match the supplied transition from states criteria; otherwise return FALSE.
ALTER MODULE object_change
ADD FUNCTION is_from_states_match
(
  p_model_states INTEGER, p_from_mask INTEGER, p_bitand_match_rule CHAR(4)
)
  RETURNS BOOLEAN
BEGIN
  DECLARE v_masked_states INTEGER;

  SET v_masked_states = BITAND(p_model_states, p_from_mask);
  CASE
    WHEN p_bitand_match_rule = 'ANY' THEN RETURN TRUE;
    WHEN p_bitand_match_rule = 'ALL' AND v_masked_states = p_from_mask THEN RETURN TRUE;
    WHEN p_bitand_match_rule = 'NONE' AND v_masked_states = 0 THEN RETURN TRUE;
    WHEN p_bitand_match_rule = 'SOME' AND v_masked_states != 0 THEN RETURN TRUE;
    ELSE RETURN FALSE;
  END CASE;
END@
