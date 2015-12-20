CREATE OR REPLACE TYPE dz_json_feature_vry FORCE
AS 
VARRAY(1048576) OF dz_json_feature;
/

GRANT EXECUTE ON dz_json_feature_vry TO PUBLIC;

