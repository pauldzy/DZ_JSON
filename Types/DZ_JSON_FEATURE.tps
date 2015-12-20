CREATE OR REPLACE TYPE dz_json_feature FORCE
AUTHID CURRENT_USER
AS OBJECT (
    geometry                 MDSYS.SDO_GEOMETRY
   ,properties               dz_json_properties_vry
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_feature
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_feature(
        p_geometry     IN  MDSYS.SDO_GEOMETRY
    ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_feature(
        p_geometry     IN  MDSYS.SDO_GEOMETRY
       ,p_properties   IN  dz_json_properties_vry
    ) RETURN SELF AS RESULT
     
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION properties_count
    RETURN NUMBER
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION transform(
        p_output_srid      IN  NUMBER 
    ) RETURN MDSYS.SDO_GEOMETRY
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION toJSON(
        p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
       ,p_pretty_print     IN  NUMBER   DEFAULT NULL
       ,p_output_srid      IN  NUMBER   DEFAULT NULL
       ,p_prune_number     IN  NUMBER   DEFAULT NULL
       ,p_add_crs          IN  VARCHAR2 DEFAULT 'TRUE'
       ,p_add_bbox         IN  VARCHAR2 DEFAULT 'TRUE'
    ) RETURN CLOB

);
/

GRANT EXECUTE ON dz_json_feature TO PUBLIC;

