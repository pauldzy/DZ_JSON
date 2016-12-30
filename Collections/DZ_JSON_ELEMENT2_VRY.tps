CREATE OR REPLACE TYPE dz_json_element2_vry FORCE
AS 
VARRAY(1048576) OF dz_json_element2;
/

GRANT EXECUTE ON dz_json_element2_vry TO PUBLIC;

