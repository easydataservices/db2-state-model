--------------------------------------------------------------------------------------------------------------------------------
-- File:        procedure_TRACK_OBJECT_QUORUMS.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE object_change
ADD PROCEDURE track_object_quorums
(
  p_object_id BIGINT,
  p_object_type_id SMALLINT,
  p_model_states INTEGER,
  p_transition_id BIGINT
)
BEGIN
  -- Retrieve from states criteria of each supported state transition with quorum tracking for the specified object type.
  FOR r AS
    SELECT
      t.transition_code,
      t.from_mask,
      t.bitand_match_rule,
      CASE WHEN q.object_id IS NULL THEN FALSE ELSE TRUE END AS is_existing
    FROM
      state_transition AS t
        LEFT OUTER JOIN
      object_transition_quorum AS q
        ON
          q.transition_code = t.transition_code
    WHERE
      q.object_id = p_object_id AND
      t.object_type_id = p_object_type_id AND
      t.transition_quorum > 1
    WITH CS
  DO
    IF is_from_states_match(p_model_states, r.from_mask, r.bitand_match_rule) THEN
      -- Add new quorum tracking when the object model states match the criteria.
      IF NOT r.is_existing THEN
        INSERT INTO object_transition_quorum(object_id, transition_code, voting_from_transition_id)
        VALUES
          (p_object_id, r.transition_code, p_transition_id);
      END IF;
    ELSE
      -- Remove existing quorum tracking when the object model states no longer match the criteria.
      IF r.is_existing THEN
        DELETE FROM object_transition_quorum WHERE object_id = p_object_id AND transition_code = r.transition_code;
      END IF;
    END IF;
  END FOR;
END@
