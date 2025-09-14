--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_GET_LAST_TRANSITION.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE subscription
ADD FUNCTION get_last_transition(p_subscription_id INTEGER) RETURNS BIGINT
BEGIN
  RETURN (SELECT last_transition_id FROM subscription WHERE subscription_id = p_subscription_id WITH CS);
END@
