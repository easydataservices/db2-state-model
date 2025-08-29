--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_GET_BACKTRACK_TRANSITIONS.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE subscription
ADD FUNCTION get_backtrack_transitions(p_subscription_id INTEGER, p_subscription subscription_row)
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
  -- Return committed subscription transitions from the backtracking list.
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
      subscription_backtrack AS b
        INNER JOIN
      object_state_transition AS t
        ON
          b.subscription_id = p_subscription_id AND
          t.transition_id BETWEEN b.start_transition_id AND b.end_transition_id
        INNER JOIN
      object AS o
        ON
          o.object_id = t.object_id
    WHERE
      t.object_type_id = p_subscription.object_type_id AND
      is_committed(t.transition_id)
    ORDER BY
      t.transition_id
    FETCH FIRST p_subscription.max_result_rows ROWS ONLY
    WITH UR
  DO
    -- If the committed row is not relevant then return only transition identifier (for removal from backtrack list).
    IF is_skippable(p_subscription.object_type_id, r.transition_id) THEN
      PIPE
      (
        r.transition_id, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL
      );
    -- Otherwise return full row.
    ELSE
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
    END IF;
  END FOR;
  RETURN;
END@
