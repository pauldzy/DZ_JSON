CREATE OR REPLACE TYPE dz_json_properties FORCE
AUTHID CURRENT_USER
AS OBJECT (
    geometry            MDSYS.SDO_GEOMETRY
   ,properties_name     VARCHAR2(4000 Char)
   ,properties_string   VARCHAR2(32000 Char)
   ,properties_clob     CLOB
   ,properties_number   NUMBER
   ,properties_date     DATE
   ,properties_complex  CLOB
   ,properties_null     INTEGER
   ,properties_element  dz_json_element1_obj
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_properties
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_properties(
       p_name                IN  VARCHAR2
      ,p_properties_string   IN  VARCHAR2
   ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_properties(
       p_name                IN  VARCHAR2
      ,p_properties_clob     IN  CLOB
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_properties(
       p_name                IN  VARCHAR2
      ,p_properties_number   IN  NUMBER
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_properties(
       p_name                IN  VARCHAR2
      ,p_properties_date     IN  DATE
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_properties(
       p_name                IN  VARCHAR2
      ,p_properties_complex  IN  CLOB
   ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_properties(
       p_name                IN  VARCHAR2
      ,p_properties_element  IN  dz_json_element1_obj
   ) RETURN SELF AS RESULT
       
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION isNULL
    RETURN VARCHAR2
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION toJSON(
      p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB

);
/

GRANT EXECUTE ON dz_json_properties TO PUBLIC;

