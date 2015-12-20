CREATE OR REPLACE TYPE dz_json_properties_vry FORCE
AS 
VARRAY(1048576) OF dz_json_properties;
/

GRANT EXECUTE ON dz_json_properties_vry TO PUBLIC;

