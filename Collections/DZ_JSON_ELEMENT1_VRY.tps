CREATE OR REPLACE TYPE dz_json_element1_vry FORCE
AS 
VARRAY(1048576) OF dz_json_element1;
/

GRANT EXECUTE ON dz_json_element1_vry TO PUBLIC;

