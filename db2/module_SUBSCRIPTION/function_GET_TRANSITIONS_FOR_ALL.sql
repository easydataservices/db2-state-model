--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_GET_TRANSITIONS_FOR_ALL.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE subscription
ADD FUNCTION get_transitions_for_all(p_subscription_id INTEGER, p_subscription subscription_row)
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
    transition_client_user VARCHAR(30)
  )
BEGIN
  DECLARE v_utc_ts TIMESTAMP(3);
  DECLARE v_max_transition_id BIGINT;

  -- Find the latest committed row inserted prior to current time.
  SET v_utc_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE;
  SET v_max_transition_id =
    (
      SELECT
        MAX(transition_id)
      FROM
        object_state_transition
      WHERE
        object_type_id = p_subscription.object_type_id AND
        transition_id > p_subscription.last_transition_id AND
        transition_utc_ts < v_utc_ts
      WITH CS
    );

  -- Return subscription transition information for all transition codes.
  FOR r AS
    SELECT
      t.transition_id,
      t.object_type_id,
      t.is_quorate,
      t.transition_code,
      t.object_id,
      o.object_ref,
      t.from_states,
      t.to_states,
      t.transition_utc_ts,
      t.transition_db_user,
      t.transition_client_user
    FROM
      object_state_transition AS t
        INNER JOIN
      object AS o
        ON
          o.object_id = t.object_id
    WHERE
      t.object_type_id = p_subscription.object_type_id AND
      t.transition_id BETWEEN p_subscription.last_transition_id + 1 AND v_max_transition_id
    ORDER BY
      t.transition_id
    FETCH FIRST p_subscription.max_result_rows ROWS ONLY
    WITH UR
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
      r.transition_client_user
    );
  END FOR;
  RETURN;
END@
