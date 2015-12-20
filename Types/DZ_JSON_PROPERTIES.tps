CREATE OR REPLACE TYPE dz_json_properties FORCE
AUTHID CURRENT_USER
AS OBJECT (
    geometry            MDSYS.SDO_GEOMETRY
   ,properties_name     VARCHAR2(4000 Char)
   ,properties_string   VARCHAR2(4000 Char)
   ,properties_number   NUMBER
   ,properties_date     DATE
   ,properties_complex  CLOB
   ,properties_null     INTEGER
   
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
   ,MEMBER FUNCTION isNULL
    RETURN VARCHAR2
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION toJSONpair(
        p_leader_char      IN  VARCHAR2 DEFAULT NULL
    ) RETURN CLOB

);
/

GRANT EXECUTE ON dz_json_properties TO PUBLIC;

