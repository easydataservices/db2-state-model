--------------------------------------------------------------------------------------------------------------------------------
-- File:        module_OBJECT_INFO.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE MODULE object_info;

-- Return identifier of object with the specified object type and reference.
ALTER MODULE object_info
PUBLISH FUNCTION object_id(p_object_type_id SMALLINT, p_object_ref VARCHAR(60)) RETURNS BIGINT;

-- Return information for the specified object.
ALTER MODULE object_info
PUBLISH FUNCTION get_object(p_object_id BIGINT)
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
  );

-- Return transition information for the specified object, starting from the specified transition.
ALTER MODULE object_info
PUBLISH FUNCTION get_object_transitions(p_object_id BIGINT, p_from_transition_id BIGINT)
  RETURNS TABLE
  (
    object_id BIGINT,
    transition_id BIGINT,
    is_quorate BOOLEAN,
    from_states INTEGER,
    to_states INTEGER,
    transition_code VARCHAR(20),
    transition_utc_ts TIMESTAMP(3),
    transition_db_user VARCHAR(30),
    transition_client_user VARCHAR(30)
  );

-- Return object JSON for the specified object.
ALTER MODULE object_info
PUBLISH FUNCTION object_json(p_object_id BIGINT) RETURNS VARCHAR(2000);

-- Return transition JSON for the specified object transition.
ALTER MODULE object_info
PUBLISH FUNCTION transition_json(p_object_id BIGINT, p_transition_id BIGINT) RETURNS VARCHAR(2000);
