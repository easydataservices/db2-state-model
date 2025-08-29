--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_IS_QUORATE.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

-- Return TRUE if a quorum is reached for the specified object transition; otherwise FALSE.
ALTER MODULE object_change
ADD FUNCTION is_quorate
(
  p_object_id BIGINT,
  p_transition_code VARCHAR(20),
  p_last_change_transition_id BIGINT,
  p_transition_quorum SMALLINT,
  p_transition_user VARCHAR(30)
)
  RETURNS BOOLEAN
BEGIN
  DECLARE v_quorum_count SMALLINT DEFAULT 1;

  IF p_transition_quorum > 1 THEN
    FOR r as
      SELECT
        transition_db_user, transition_client_user
      FROM
        object_state_transition
      WHERE
        object_id = p_object_id AND
        transition_code = p_transition_code AND
        transition_id > p_last_change_transition_id
      WITH CS
    DO
      IF
        r.transition_client_user = p_transition_user OR
        (r.transition_client_user IS NULL AND r.transition_db_user = SESSION_USER)
      THEN
        SIGNAL SQLSTATE 'SM004' SET MESSAGE_TEXT = 'User has already voted';
      END IF;
      SET v_quorum_count = v_quorum_count + 1;
    END FOR;
  END IF;
  
  IF v_quorum_count < p_transition_quorum THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END@
