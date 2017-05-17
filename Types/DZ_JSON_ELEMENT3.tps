CREATE OR REPLACE TYPE dz_json_element3 FORCE
AUTHID CURRENT_USER
AS OBJECT (
    element_name       VARCHAR2(4000 Char)
   ,element_string     VARCHAR2(4000 Char)
   ,element_number     NUMBER
   ,element_date       DATE
   ,element_complex    CLOB
   ,element_clob       CLOB
   ,element_string_vry MDSYS.SDO_STRING2_ARRAY
   ,element_number_vry MDSYS.SDO_NUMBER_ARRAY
   ,element_null       INTEGER
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element3
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element3(
       p_name                IN  VARCHAR2
      ,p_element_string      IN  VARCHAR2
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element3(
       p_name                IN  VARCHAR2
      ,p_element_number      IN  NUMBER
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element3(
       p_name                IN  VARCHAR2
      ,p_element_date        IN  DATE
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element3(
       p_name                IN  VARCHAR2
      ,p_element_complex     IN  CLOB
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

GRANT EXECUTE ON dz_json_element3 TO PUBLIC;

