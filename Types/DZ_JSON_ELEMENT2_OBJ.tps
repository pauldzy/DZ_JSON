CREATE OR REPLACE TYPE dz_json_element2_obj FORCE
AUTHID CURRENT_USER
AS OBJECT (
    elements         dz_json_element2_vry
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2_obj
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2_obj(
      p_elements     IN  dz_json_element2_vry
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION toJSON(
      p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB

);
/

GRANT EXECUTE ON dz_json_element2_obj TO PUBLIC;

