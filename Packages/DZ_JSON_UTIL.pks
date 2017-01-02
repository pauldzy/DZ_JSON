CREATE OR REPLACE PACKAGE dz_json_util
AUTHID CURRENT_USER
AS
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN  VARCHAR2
      ,p_regex            IN  VARCHAR2
      ,p_match            IN  VARCHAR2 DEFAULT NULL
      ,p_end              IN  NUMBER   DEFAULT 0
      ,p_trim             IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN  VARCHAR2
      ,p_null_replacement IN  NUMBER DEFAULT NULL
   ) RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION strings2numbers(
      p_input             IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN MDSYS.SDO_NUMBER_ARRAY;
   
   ----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION true_point(
      p_input             IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2d(
      p_input             IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2dM(
      p_input         IN  MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_3d(
      p_input      IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number(
       p_input            IN  NUMBER
      ,p_trunc            IN  NUMBER DEFAULT NULL
   ) RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_varchar2(
       p_input            IN  NUMBER
      ,p_trunc            IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_clob(
       p_input            IN  NUMBER
      ,p_trunc            IN  NUMBER DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION pretty_str(
       p_input            IN  VARCHAR2
      ,p_level            IN  NUMBER
      ,p_amount           IN  VARCHAR2 DEFAULT '   '
      ,p_linefeed         IN  VARCHAR2 DEFAULT CHR(10)
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION pretty(
       p_input            IN  CLOB
      ,p_level            IN  NUMBER
      ,p_amount           IN  VARCHAR2 DEFAULT '   '
      ,p_linefeed         IN  VARCHAR2 DEFAULT CHR(10)
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input         IN OUT MDSYS.SDO_NUMBER_ARRAY
      ,p_value         IN     MDSYS.SDO_NUMBER_ARRAY
      ,p_unique        IN     VARCHAR2 DEFAULT 'FALSE'
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input         IN OUT MDSYS.SDO_NUMBER_ARRAY
      ,p_value         IN     NUMBER
      ,p_unique        IN     VARCHAR2 DEFAULT 'FALSE'
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input         IN OUT MDSYS.SDO_STRING2_ARRAY
      ,p_value         IN     MDSYS.SDO_STRING2_ARRAY
      ,p_unique        IN     VARCHAR2 DEFAULT 'FALSE'
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input         IN OUT MDSYS.SDO_STRING2_ARRAY
      ,p_value         IN     VARCHAR2
      ,p_unique        IN     VARCHAR2 DEFAULT 'FALSE'
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION a_in_b(
       p_input_a          IN  NUMBER
      ,p_input_b          IN  MDSYS.SDO_NUMBER_ARRAY
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION a_in_b(
       p_input_a          IN  MDSYS.SDO_NUMBER_ARRAY
      ,p_input_b          IN  MDSYS.SDO_NUMBER_ARRAY
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION a_in_b(
       p_input_a          IN  VARCHAR2
      ,p_input_b          IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION a_in_b(
       p_input_a          IN  MDSYS.SDO_STRING2_ARRAY
      ,p_input_b          IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sort_string(
       p_input_array      IN  MDSYS.SDO_STRING2_ARRAY
      ,p_direction        IN  VARCHAR2 DEFAULT 'ASC'
      ,p_unique           IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sort_number(
       p_input_array      IN  MDSYS.SDO_NUMBER_ARRAY
      ,p_direction        IN  VARCHAR2 DEFAULT 'ASC'
      ,p_unique           IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_NUMBER_ARRAY;
   
END dz_json_util;
/

GRANT EXECUTE ON dz_json_util TO PUBLIC;

