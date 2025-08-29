--------------------------------------------------------------------------------------------------------------------------------
-- File:        function_OBJECT_ID.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE object_info
ADD FUNCTION object_id(p_object_type_id SMALLINT, p_object_ref VARCHAR(60)) RETURNS BIGINT
BEGIN
  DECLARE v_object_id BIGINT;

  -- Look up and return object.
  SET v_object_id =
    (SELECT object_id FROM object WHERE object_type_id = p_object_type_id AND object_ref = p_object_ref WITH CS);
    RETURN v_object_id;
END@
