--------------------------------------------------------------------------------------------------------------------------------
-- File:        module_AUXILIARY.sql
--              (c) Copyright Jeremy Rickard 2025
--------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE MODULE auxiliary;

-- Return boolean indicating whether or not the supplied text is a valid JSON document.
ALTER MODULE auxiliary
PUBLISH FUNCTION is_json_document(p_json VARCHAR(2000)) RETURNS BOOLEAN;
