--------------------------------------------------------------------------------------------------------------------------------
-- File:        procedure_ADD_OBJECT.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE object_change
ADD PROCEDURE add_object
(
  p_object_type_id SMALLINT,
  p_object_ref VARCHAR(60),
  p_object_json VARCHAR(2000),
  p_creation_user VARCHAR(30),
  OUT p_object_id BIGINT
)
BEGIN
  DECLARE v_utc_ts TIMESTAMP(3);
  DECLARE v_creator_role VARCHAR(30);
  DECLARE v_transition_id BIGINT;

  -- Get current UTC time.
  SET v_utc_ts = CURRENT_TIMESTAMP - CURRENT_TIMEZONE;

  -- Look up object type details.
  SET v_creator_role = (SELECT creator_role FROM object_type WHERE object_type_id = p_object_type_id WITH CS);

  -- Signal an exception when the specified P_OBJECT_TYPE_ID is invalid.
  IF v_creator_role IS NULL THEN
    SIGNAL SQLSTATE 'SM001' SET MESSAGE_TEXT = 'Illegal P_OBJECT_TYPE_ID value';
  END IF;

  -- Signal an exception when the user lacks the necessary authority.
  IF VERIFY_ROLE_FOR_USER(SESSION_USER, v_creator_role) = 0 THEN
    SIGNAL SQLSTATE 'SM002' SET MESSAGE_TEXT = 'Not authorised';
  END IF;

  -- Look up existing object.
  SET p_object_ref = RTRIM(p_object_ref);
  SET p_object_id =
    (SELECT object_id FROM object WHERE object_type_id = p_object_type_id AND object_ref = p_object_ref WITH CS);

  -- Exit if an existing object was found.
  IF p_object_id IS NOT NULL THEN
    RETURN 0;
  END IF;

  -- If the object does not exist then add it.
  BEGIN
    -- Handle duplicate insert resulting from rare synchronisation.
    DECLARE EXIT HANDLER FOR SQLSTATE '23505'
      SET p_object_id =
        (SELECT object_id FROM object WHERE object_type_id = p_object_type_id AND object_ref = p_object_ref WITH CS);

    SET p_object_id = NEXT VALUE FOR object_id;
    INSERT INTO object(object_id, object_type_id, object_ref) VALUES (p_object_id, p_object_type_id, p_object_ref);
    CALL apply_transition(p_object_id, '_INIT', p_creation_user, p_object_json, v_transition_id);
    UPDATE object SET initial_transition_id = v_transition_id WHERE object_id = p_object_id;
  END;
END@
