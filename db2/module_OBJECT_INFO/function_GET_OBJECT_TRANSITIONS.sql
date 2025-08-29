--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_GET_OBJECT_TRANSITIONS.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE object_info
ADD FUNCTION get_object_transitions(p_object_id BIGINT, p_from_transition_id BIGINT)
  RETURNS TABLE
  (
    object_id BIGINT,
    transition_id BIGINT,
    is_quorate BOOLEAN,
    from_states INTEGER,
    to_states INTEGER,
    transition_code VARCHAR(20),
    transition_utc_ts TIMESTAMP(3),
    transition_db_user VARCHAR(30),
    transition_client_user VARCHAR(30)
  )
BEGIN
  DECLARE v_object_type_id SMALLINT;
  DECLARE v_initial_transition_id BIGINT;
  DECLARE v_viewer_role VARCHAR(30);

  -- Look up object details.
  SET (v_object_type_id, v_initial_transition_id) =
    (SELECT object_type_id, initial_transition_id FROM object WHERE object_id = p_object_id WITH CS);

  -- Signal an exception when the specified P_OBJECT_ID is invalid.
  IF v_object_type_id IS NULL THEN
    SIGNAL SQLSTATE 'SM001' SET MESSAGE_TEXT = 'Illegal P_OBJECT_ID value';
  END IF;

  -- Look up object type details.
  SET v_viewer_role = (SELECT viewer_role FROM object_type WHERE object_type_id = v_object_type_id WITH CS);

  -- Signal an exception when the user lacks the necessary authority.
  IF VERIFY_ROLE_FOR_USER(SESSION_USER, v_viewer_role) = 0 THEN
    SIGNAL SQLSTATE 'SM002' SET MESSAGE_TEXT = 'Not authorised';
  END IF;

  -- Return transition information for the specified object (but excluding _INIT transition).
  SET p_from_transition_id = COALESCE(p_from_transition_id, 0);
  FOR r AS
    SELECT
      object_id,
      transition_id,
      is_quorate,
      from_states,
      to_states,
      transition_code,
      transition_utc_ts,
      transition_db_user,
      transition_client_user
    FROM
      object_state_transition
    WHERE
      object_id = p_object_id AND
      transition_id >= p_from_transition_id AND
      transition_id > v_initial_transition_id
    ORDER BY
      transition_id
    WITH CS
  DO
    PIPE
    (
      r.object_id,
      r.transition_id,
      r.is_quorate,
      r.from_states,
      r.to_states,
      r.transition_code,
      r.transition_utc_ts,
      r.transition_db_user,
      r.transition_client_user
    );
  END FOR;
  RETURN;
END@
