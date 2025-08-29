--------------------------------------------------------------------------------------------------------------------------------
-- File:        procedure_SET_LAST_TRANSITION.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE subscription
ADD PROCEDURE set_last_transition(p_subscription_id INTEGER, p_transition_id BIGINT)
BEGIN
  DECLARE v_utc_ts TIMESTAMP(3);
  DECLARE v_subscription_role VARCHAR(30);
  DECLARE v_backtrack_limit_minutes SMALLINT;

  -- Get current UTC time.
  SET v_utc_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE;

  -- Look up subscription.
  SET (v_subscription_role, v_backtrack_limit_minutes) =
    (SELECT subscription_role, backtrack_limit_minutes FROM subscription WHERE subscription_id = p_subscription_id WITH CS);

  -- Signal an exception when the specified P_SUBSCRIPTION_ID is invalid.
  IF v_subscription_role IS NULL THEN
    SIGNAL SQLSTATE 'SM001' SET MESSAGE_TEXT = 'Illegal P_SUBSCRIPTION_ID value';
  END IF;

  -- Signal an exception when the user lacks the necessary authority.
  IF VERIFY_ROLE_FOR_USER(SESSION_USER, v_subscription_role) = 0 THEN
    SIGNAL SQLSTATE 'SM002' SET MESSAGE_TEXT = 'Not authorised';
  END IF;

  -- Remove backtrack transitions older than the retention limit.
  DELETE FROM subscription_backtrack
  WHERE
    subscription_id = p_subscription_id AND backtrack_added_utc_ts < v_utc_ts - v_backtrack_limit_minutes MINUTES;

  -- Update the last processed transition id.
  UPDATE subscription SET last_transition_id = MAX(last_transition_id, p_transition_id) WHERE subscription_id = p_subscription_id;
END@
