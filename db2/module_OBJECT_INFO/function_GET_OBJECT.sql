--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_GET_OBJECT.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE object_info
ADD FUNCTION get_object(p_object_id BIGINT)
  RETURNS TABLE
  (
    object_id BIGINT,
    object_type_id SMALLINT,
    object_ref VARCHAR(60),
    creation_utc_ts TIMESTAMP(3),
    creation_db_user VARCHAR(30),
    creation_client_user VARCHAR(30),
    model_states INTEGER,
    last_change_transition_id BIGINT
  )
BEGIN
  DECLARE v_object_type_id SMALLINT;
  DECLARE v_viewer_role VARCHAR(30);
  DECLARE v_initial_transition_id BIGINT;

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

  -- Return information for the specified object.
  FOR r AS
    SELECT
      o.object_id,
      o.object_type_id,
      o.object_ref,
      t.transition_utc_ts AS creation_utc_ts,
      t.transition_db_user AS creation_db_user,
      t.transition_client_user AS creation_client_user,
      o.model_states,
      o.last_change_transition_id
    FROM
      object AS o
        INNER JOIN
      object_state_transition AS t
        ON
          t.object_id = o.object_id AND
          t.transition_id = o.initial_transition_id
    WHERE
      o.object_id = p_object_id
    WITH CS
  DO
    PIPE
    (
      r.object_id,
      r.object_type_id,
      r.object_ref,
      r.creation_utc_ts,
      r.creation_db_user,
      r.creation_client_user,
      r.model_states,
      CASE WHEN r.last_change_transition_id = v_initial_transition_id THEN 0 ELSE r.last_change_transition_id END
    );
  END FOR;
  RETURN;
END@
