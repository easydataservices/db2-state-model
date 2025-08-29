--------------------------------------------------------------------------------------------------------------------------------
-- File:        procedure_REMOVE_BACKTRACK_TRANSITION.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE subscription
ADD PROCEDURE remove_backtrack_transition(p_subscription_id INTEGER, p_transition_id BIGINT)
BEGIN
  DECLARE v_subscription_role VARCHAR(30);
  DECLARE v_utc_ts TIMESTAMP(3);
  DECLARE v_start_transition_id BIGINT;
  DECLARE v_end_transition_id BIGINT;

  -- Look up subscription.
  SET v_subscription_role = (SELECT subscription_role FROM subscription WHERE subscription_id = p_subscription_id WITH CS);

  -- Signal an exception when the specified P_SUBSCRIPTION_ID is invalid.
  IF v_subscription_role IS NULL THEN
    SIGNAL SQLSTATE 'SM001' SET MESSAGE_TEXT = 'Illegal P_SUBSCRIPTION_ID value';
  END IF;

  -- Signal an exception when the user lacks the necessary authority.
  IF VERIFY_ROLE_FOR_USER(SESSION_USER, v_subscription_role) = 0 THEN
    SIGNAL SQLSTATE 'SM002' SET MESSAGE_TEXT = 'Not authorised';
  END IF;

  -- Retrieve details of the row containing the backtrack transition.
  SET (v_start_transition_id, v_end_transition_id, v_utc_ts) =
    (
      SELECT
        start_transition_id, end_transition_id, backtrack_added_utc_ts
      FROM
        subscription_backtrack
      WHERE
        subscription_id = p_subscription_id AND
        p_transition_id BETWEEN start_transition_id AND end_transition_id
      WITH CS
    );

  -- Remove the transition from the backtrack list.
  CASE
    WHEN v_start_transition_id = v_end_transition_id THEN
      DELETE FROM subscription_backtrack WHERE subscription_id = p_subscription_id AND start_transition_id = p_transition_id;
    WHEN v_start_transition_id = p_transition_id THEN
      UPDATE subscription_backtrack
      SET
        start_transition_id = start_transition_id + 1
      WHERE
        subscription_id = p_subscription_id AND
        start_transition_id = p_transition_id;
    WHEN v_end_transition_id = p_transition_id THEN
      UPDATE subscription_backtrack
      SET
        end_transition_id = end_transition_id - 1
      WHERE
        subscription_id = p_subscription_id AND
        end_transition_id = p_transition_id;
    ELSE
      IF v_start_transition_id IS NOT NULL THEN
        DELETE FROM subscription_backtrack
        WHERE
          subscription_id = p_subscription_id AND p_transition_id BETWEEN start_transition_id AND end_transition_id;
        INSERT INTO subscription_backtrack(subscription_id, start_transition_id, end_transition_id, backtrack_added_utc_ts)
        VALUES
          (p_subscription_id, v_start_transition_id, p_transition_id - 1, v_utc_ts),
          (p_subscription_id, p_transition_id + 1, v_end_transition_id, v_utc_ts);
      END IF;
  END CASE;
END@
