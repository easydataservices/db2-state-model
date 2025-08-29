--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_GET_ALL_STATES.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE model_info
ADD FUNCTION get_all_states(p_object_type_id SMALLINT)
  RETURNS TABLE
  (
    model_id INTEGER,
    bit_index SMALLINT,
    state_code VARCHAR(20)
  )
BEGIN
  FOR r AS
    SELECT
      model_id, bit_index, state_code
    FROM
      model_state
    WHERE
      object_type_id = p_object_type_id
    ORDER BY
      model_id, bit_index
    WITH CS
  DO
    PIPE (r.model_id, r.bit_index, r.state_code);
  END FOR;
  RETURN;
END@
