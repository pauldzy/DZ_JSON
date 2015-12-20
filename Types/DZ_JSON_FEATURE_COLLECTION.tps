CREATE OR REPLACE TYPE dz_json_feature_collection FORCE
AUTHID CURRENT_USER
AS OBJECT (
    features         dz_json_feature_vry
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_feature_collection
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_json_feature_collection(
        p_features     IN  dz_json_feature_vry
    ) RETURN SELF AS RESULT
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION feature_count
    RETURN NUMBER
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION bbox(
        p_output_srid  IN  NUMBER DEFAULT NULL
       ,p_prune_number IN  NUMBER DEFAULT NULL
    ) RETURN VARCHAR2
    
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

GRANT EXECUTE ON dz_json_feature_collection TO PUBLIC;

