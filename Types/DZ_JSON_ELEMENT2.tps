CREATE OR REPLACE TYPE dz_json_element2 FORCE
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
   ,element_obj        dz_json_element3_obj
   ,element_vry        dz_json_element3_vry
   ,element_obj_vry    dz_json_element3_obj_vry
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_string      IN  VARCHAR2
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_number      IN  NUMBER
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_date        IN  DATE
   ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_string_vry  IN  MDSYS.SDO_STRING2_ARRAY
      ,p_unique_flag         IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_number_vry  IN  MDSYS.SDO_NUMBER_ARRAY
   ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_clob        IN  CLOB
   ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_complex     IN  CLOB
   ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_obj         IN  dz_json_element3_obj
   ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_vry         IN  dz_json_element3_vry
   ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_obj_vry     IN  dz_json_element3_obj_vry
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

GRANT EXECUTE ON dz_json_element2 TO PUBLIC;

