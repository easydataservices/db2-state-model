--------------------------------------------------------------------------------------------------------------------------------
-- File:        procedure_APPLY_TRANSITION.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE object_change
ADD PROCEDURE apply_transition
(
  p_object_id BIGINT,
  p_transition_code VARCHAR(20),
  p_transition_user VARCHAR(30),
  p_transition_json VARCHAR(2000),
  OUT p_transition_id BIGINT
)
BEGIN
  DECLARE v_utc_ts TIMESTAMP(3);
  DECLARE v_object ANCHOR DATA TYPE TO ROW OF object;
  DECLARE v_statra ANCHOR DATA TYPE TO ROW OF state_transition;
  DECLARE v_new_model_states INTEGER;
  DECLARE v_is_quorate BOOLEAN;

  -- Get current UTC time.
  SET v_utc_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE;

  -- Look up object, and lock it against parallel changes.
  SET (v_object.object_type_id, v_object.model_states, v_object.last_change_transition_id) =
    (
      SELECT
        object_type_id, model_states, last_change_transition_id
      FROM
        object
      WHERE
        object_id = p_object_id
      WITH RR USE AND KEEP UPDATE LOCKS
    );

  -- Signal an exception when the specified object is invalid.
  IF v_object.object_type_id IS NULL THEN
    SIGNAL SQLSTATE 'SM001' SET MESSAGE_TEXT = 'Unknown P_OBJECT_ID';
  END IF;

  -- Signal an exception when the specified P_OBJECT_JSON is invalid.
  SET p_transition_json = COALESCE(p_transition_json, '{}');
  IF NOT auxiliary.is_json_document(p_transition_json) THEN
    SIGNAL SQLSTATE 'SM009' SET MESSAGE_TEXT = 'P_OBJECT_JSON is not a valid JSON document';
  END IF;

  -- Look up state transition details.
  SET
    (
      v_statra.transition_role,
      v_statra.from_mask,
      v_statra.bitand_match_rule,
      v_statra.to_mask_off,
      v_statra.to_mask_on,
      v_statra.transition_quorum
    ) =
    (
      SELECT
        transition_role,
        from_mask,
        bitand_match_rule,
        to_mask_off,
        to_mask_on,
        transition_quorum
      FROM
        state_transition
      WHERE
        object_type_id = v_object.object_type_id AND
        transition_code = p_transition_code
      WITH CS
    );

  -- Signal an exception when the user lacks the necessary authority.
  IF VERIFY_ROLE_FOR_USER(SESSION_USER, v_statra.transition_role) = 0 THEN
    SIGNAL SQLSTATE 'SM002' SET MESSAGE_TEXT = 'Not authorised';
  END IF;

  -- Signal an exception when the transition from states do not match the object states.
  IF NOT is_from_states_match(v_object.model_states, v_statra.from_mask, v_statra.bitand_match_rule) THEN
    SIGNAL SQLSTATE 'SM003' SET MESSAGE_TEXT = 'Invalid transition from current state';
  END IF;

  -- If a quorum is required then determine whether that quorum is reached.
  SET v_is_quorate = 
    is_quorate
    (
      p_object_id, p_transition_code, v_object.last_change_transition_id, v_statra.transition_quorum, p_transition_user
    );

  -- Calculate new model states.
  SET v_new_model_states =
    BITOR(BITANDNOT(v_object.model_states, v_statra.to_mask_off), v_statra.to_mask_on);

  -- Insert transition row.
  SET p_transition_id = NEXT VALUE FOR transition_id;
  INSERT INTO object_state_transition
  (
    object_id,
    transition_id,
    is_quorate,
    from_states,
    to_states,
    object_type_id,
    transition_code,
    transition_utc_ts,
    transition_db_user,
    transition_client_user,
    transition_json
  )
  VALUES
    (
      p_object_id,
      p_transition_id,
      v_is_quorate,
      v_object.model_states,
      v_new_model_states,
      v_object.object_type_id,
      p_transition_code,
      v_utc_ts,
      SESSION_USER,
      p_transition_user,
      p_transition_json
    );

  -- If the transition is quorate then update the object.
  IF v_is_quorate THEN
    UPDATE object
    SET
      model_states = v_new_model_states,
      last_change_transition_id = p_transition_id
    WHERE
      object_id = p_object_id;

    -- Update quorum tracking for the new state.
    CALL track_object_quorums(p_object_id, v_object.object_type_id, v_new_model_states, p_transition_id);
  END IF;
END@
