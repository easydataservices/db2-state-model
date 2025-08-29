--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_TRANSITION_JSON.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE object_info
ADD FUNCTION transition_json(p_object_id BIGINT, p_transition_id BIGINT) RETURNS VARCHAR(2000)
BEGIN
  DECLARE v_object_type_id SMALLINT;
  DECLARE v_viewer_role VARCHAR(30);
  DECLARE v_json_viewer_role VARCHAR(30);
  DECLARE v_transition_json VARCHAR(2000);

  -- Look up object details.
  SET v_object_type_id = (SELECT object_type_id FROM object WHERE object_id = p_object_id WITH CS);

  -- Signal an exception when the specified P_OBJECT_ID is invalid.
  IF v_object_type_id IS NULL THEN
    SIGNAL SQLSTATE 'SM001' SET MESSAGE_TEXT = 'Illegal P_OBJECT_ID value';
  END IF;

  -- Look up object type details.
  SET (v_viewer_role, v_json_viewer_role) =
    (SELECT viewer_role, json_viewer_role FROM object_type WHERE object_type_id = v_object_type_id WITH CS);

  -- Signal an exception when the user lacks the necessary authority.
  IF VERIFY_ROLE_FOR_USER(SESSION_USER, v_viewer_role) = 0 OR VERIFY_ROLE_FOR_USER(SESSION_USER, v_json_viewer_role) = 0 THEN
    SIGNAL SQLSTATE 'SM002' SET MESSAGE_TEXT = 'Not authorised';
  END IF;

  -- Retrieve and return transition JSON for the specified object transition.
  SET v_transition_json =
    (
      SELECT transition_json FROM object_state_transition WHERE object_id = p_object_id AND transition_id = p_transition_id
      WITH CS
    );
  RETURN v_transition_json;
END@
