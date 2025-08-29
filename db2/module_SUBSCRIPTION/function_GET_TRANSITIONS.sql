--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_GET_TRANSITIONS.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE subscription
ADD FUNCTION get_transitions(p_subscription_id INTEGER)
  RETURNS TABLE
  (
    transition_id BIGINT,
    object_type_id SMALLINT,
    is_quorate BOOLEAN,
    transition_code VARCHAR(20),
    object_id BIGINT,
    object_ref VARCHAR(60),
    from_states INTEGER,
    to_states INTEGER,
    transition_utc_ts TIMESTAMP(3),
    transition_db_user VARCHAR(30),
    transition_client_user VARCHAR(30),
    is_backtrack BOOLEAN,
    is_data_missing BOOLEAN,
    is_committed BOOLEAN
  )
BEGIN
  DECLARE v_subscription subscription_row;
  DECLARE v_row_count SMALLINT DEFAULT 0;
  DECLARE v_previous_transition_id BIGINT;

  -- Look up subscription.
  SET
    (
      v_subscription.subscription_role,
      v_subscription.object_type_id,
      v_subscription.transition_code,
      v_subscription.max_result_rows,
      v_subscription.last_transition_id
    ) =
    (
      SELECT
        subscription_role, object_type_id, transition_code, max_result_rows, last_transition_id
      FROM
        subscription
      WHERE
        subscription_id = p_subscription_id
      WITH CS
    );

  -- Signal an exception when the specified P_SUBSCRIPTION_ID is invalid.
  IF v_subscription.subscription_role IS NULL THEN
    SIGNAL SQLSTATE 'SM001' SET MESSAGE_TEXT = 'Illegal P_SUBSCRIPTION_ID value';
  END IF;

  -- Signal an exception when the user lacks the necessary authority.
  IF VERIFY_ROLE_FOR_USER(SESSION_USER, v_subscription.subscription_role) = 0 THEN
    SIGNAL SQLSTATE 'SM002' SET MESSAGE_TEXT = 'Not authorised';
  END IF;

  -- Initialise previous transition identifier.
  SET v_previous_transition_id = v_subscription.last_transition_id;

  -- Return subscription backtrack transitions.
  FOR r AS SELECT * FROM TABLE(get_backtrack_transitions(p_subscription_id, v_subscription))
  DO
    PIPE
    (
      r.transition_id,
      r.object_type_id,
      r.is_quorate,
      r.transition_code,
      r.object_id,
      r.object_ref,
      r.from_states,
      r.to_states,
      r.transition_utc_ts,
      r.transition_db_user,
      r.transition_client_user,
      TRUE,
      FALSE,
      TRUE
    );

    SET v_row_count = v_row_count + 1;
    IF v_row_count >= v_subscription.max_result_rows THEN
      RETURN;
    END IF;
  END FOR;

  -- Return subscription transition information.
  IF v_subscription.transition_code IS NULL THEN
    FOR r AS SELECT * FROM TABLE(get_transitions_for_all(p_subscription_id, v_subscription))
    DO
      PIPE
      (
        r.transition_id,
        r.object_type_id,
        r.is_quorate,
        r.transition_code,
        r.object_id,
        r.object_ref,
        r.from_states,
        r.to_states,
        r.transition_utc_ts,
        r.transition_db_user,
        r.transition_client_user,
        FALSE,
        is_data_missing(v_subscription.object_type_id, v_previous_transition_id, r.transition_id),
        is_committed(r.transition_id)
      );

      SET v_previous_transition_id = r.transition_id;
      SET v_row_count = v_row_count + 1;
      IF v_row_count >= v_subscription.max_result_rows THEN
        RETURN;
      END IF;
    END FOR;
  ELSE
    FOR r AS SELECT * FROM TABLE(get_transitions_for_code(p_subscription_id, v_subscription))
    DO
      PIPE
      (
        r.transition_id,
        r.object_type_id,
        r.is_quorate,
        r.transition_code,
        r.object_id,
        r.object_ref,
        r.from_states,
        r.to_states,
        r.transition_utc_ts,
        r.transition_db_user,
        r.transition_client_user,
        FALSE,
        is_data_missing(v_subscription.object_type_id, v_previous_transition_id, r.transition_id),
        is_committed(r.transition_id)
      );

      SET v_previous_transition_id = r.transition_id;
      SET v_row_count = v_row_count + 1;
      IF v_row_count >= v_subscription.max_result_rows THEN
        RETURN;
      END IF;
    END FOR;
  END IF;
  RETURN;
END@
