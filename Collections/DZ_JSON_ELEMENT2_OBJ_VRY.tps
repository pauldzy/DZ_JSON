CREATE OR REPLACE TYPE dz_json_element2_obj_vry FORCE
AS 
VARRAY(1048576) OF dz_json_element2_obj;
/

GRANT EXECUTE ON dz_json_element2_obj_vry TO PUBLIC;

