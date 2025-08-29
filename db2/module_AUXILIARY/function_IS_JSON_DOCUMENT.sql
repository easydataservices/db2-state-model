--------------------------------------------------------------------------------------------------------------------------------
-- File:        IS_JSON_DOCUMENT.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

ALTER MODULE auxiliary
ADD FUNCTION is_json_document(p_json VARCHAR(2000)) RETURNS BOOLEAN
BEGIN
  -- Handler for invalid JSON
  DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    RETURN FALSE;

  -- Check text specifes a JSON document.
  IF LTRIM(p_json) NOT LIKE '{%' OR JSON_TO_BSON(p_json) IS NULL THEN
    SIGNAL SQLSTATE 'SM009';
  END IF;

  -- Return.
  RETURN TRUE;
END@
