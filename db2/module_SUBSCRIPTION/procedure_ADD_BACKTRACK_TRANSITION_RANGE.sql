--------------------------------------------------------------------------------------------------------------------------------
-- File:        procedure_ADD_BACKTRACK_TRANSITION.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE subscription
ADD PROCEDURE add_backtrack_transition_range
(
  p_subscription_id INTEGER, p_start_transition_id BIGINT, p_end_transition_id BIGINT
)
BEGIN
  DECLARE v_utc_ts TIMESTAMP(3);
  DECLARE v_subscription_role VARCHAR(30);
  DECLARE v_object_type_id SMALLINT;
  DECLARE v_transition_id BIGINT;
  DECLARE v_range_start_id BIGINT;
  DECLARE v_range_end_id BIGINT;
  DECLARE v_is_write_needed BOOLEAN;

  -- Get current UTC time.
  SET v_utc_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE;

  -- Look up subscription.
  SET (v_subscription_role, v_object_type_id) =
    (SELECT subscription_role, object_type_id FROM subscription WHERE subscription_id = p_subscription_id WITH CS);

  -- Signal an exception when the specified P_SUBSCRIPTION_ID is invalid.
  IF v_subscription_role IS NULL THEN
    SIGNAL SQLSTATE 'SM001' SET MESSAGE_TEXT = 'Illegal P_SUBSCRIPTION_ID value';
  END IF;

  -- Signal an exception when the user lacks the necessary authority.
  IF VERIFY_ROLE_FOR_USER(SESSION_USER, v_subscription_role) = 0 THEN
    SIGNAL SQLSTATE 'SM002' SET MESSAGE_TEXT = 'Not authorised';
  END IF;

  -- Scan the specified transition range for sub-ranges that need to be added to the backtrack list.
  -- Transitions relating to non-target object types are omitted.
  SET v_transition_id = p_start_transition_id;
  SET v_is_write_needed = FALSE;
  WHILE v_transition_id <= p_end_transition_id DO
    -- Detect start or end of a sub-range.
    IF is_skippable(v_object_type_id, v_transition_id) THEN
      IF v_range_start_id IS NOT NULL THEN
        SET v_range_end_id = v_transition_id - 1;
        SET v_is_write_needed = TRUE;
      END IF;
    ELSE
      IF v_range_start_id IS NULL THEN
        SET v_range_start_id = v_transition_id;
      END IF;
      IF v_transition_id = p_end_transition_id THEN
        SET v_range_end_id = p_end_transition_id;
        SET v_is_write_needed = TRUE;
      END IF;
    END IF;

    -- Once a sub-range start and end is determined, insert the range of transitions into the backtrack list.
    IF v_is_write_needed THEN
      INSERT INTO subscription_backtrack(subscription_id, start_transition_id, end_transition_id, backtrack_added_utc_ts)
      VALUES
        (p_subscription_id, v_range_start_id, v_range_end_id, v_utc_ts);
      SET (v_is_write_needed, v_range_start_id, v_range_end_id) = (FALSE, NULL, NULL);
    END IF;

    -- Move to next transition.
    SET v_transition_id = v_transition_id + 1;
  END WHILE;
END@
