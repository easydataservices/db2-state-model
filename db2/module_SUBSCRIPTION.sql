--------------------------------------------------------------------------------------------------------------------------------
-- File:        module_SUBSCRIPTION.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE MODULE subscription;

-- Return subscription transitions.
ALTER MODULE subscription
PUBLISH FUNCTION get_transitions(p_subscription_id INTEGER)
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
  );

-- Acknowledge last processed transition.
ALTER MODULE subscription
PUBLISH PROCEDURE set_last_transition(p_subscription_id INTEGER, p_transition_id BIGINT);

-- Add range of transitions to the subscription backtrack list.
ALTER MODULE subscription
PUBLISH PROCEDURE add_backtrack_transition_range
(
  p_subscription_id INTEGER, p_start_transition_id BIGINT, p_end_transition_id BIGINT
);

-- Remove a transition from the subscription backtrack list.
ALTER MODULE subscription
PUBLISH PROCEDURE remove_backtrack_transition(p_subscription_id INTEGER, p_transition_id BIGINT);
