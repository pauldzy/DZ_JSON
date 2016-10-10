CREATE OR REPLACE PACKAGE dz_json_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_JSON
     
   - Build ID: DZBUILDIDDZ
   - TFS Change Set: DZCHANGESETDZ
   
   Utility for the creation of JSON and GeoJSON from Oracle data types and
   structures.  Support for the deserialization of JSON is not implemented.
   
   */
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.geojson2sdo

   Unimplemented function to convert GeoJSON into SDO_GEOMETRY.  The plan as
   much as there is one is to implement this using Oracle 12c JSON toolset.

   Parameters:

      p_input - GeoJSON geometry as CLOB
      p_srid - Optional SRID value to apply to resulting SDO_GEOMETRY.

   Returns:

      MDSYS.SDO_GEOMETRY spatial type
      
   Notes:
   
   -  If no SRID is provided, then the resulting SDO_GEOMETRY will receive
      WGS84 geodetic SRID 8307 per GeoJSON specifications.

   */
   FUNCTION geojson2sdo(
       p_input            IN  CLOB
      ,p_srid             IN  NUMBER DEFAULT NULL
   ) RETURN MDSYS.SDO_GEOMETRY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.sdo2geojson

   Function to convert SDO_GEOMETRY into GeoJSON geometry object.  Currently
   supports simple point, linestring, polygon, multipoint, point cluster,
   multilinestring, multipolygon and collection geometry types.  As GeoJSON
   does not currently support complex curve geometries, use SDO_ARC_DENSIFY to
   densify any such geometries before using this function.

   Parameters:

      p_input - SDO_GEOMETRY
      p_pretty_print - Optional JSON formatter.
      p_2d_flag - Optional TRUE/FALSE flag to remove 3rd and 4th dimensions.
      p_output_srid - Optional SRID to transform geometry before conversion.
      p_prune_number - Optional length to truncate precision of ordinates.

   Returns:

      CLOB of GeoJSON geometry object
      
   Notes:
   
   -  Leave pretty print value NULL to output compact JSON.  Use zero for 
      pretty print formatting.  Larger values will continually indent the JSON 
      three spaces to the right.
      
   -  The GeoJSON geometry object does not itself carry coordinate system 
      information outside of a feature or feature collection object.  Use
      the GeoJSON default of WGS84 (8307 or 4326) for output without further 
      documentation.  

   */
   FUNCTION sdo2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.sdo2bbox

   Function to convert SDO_GEOMETRY into four ordinate JSON array of 
   [minx,miny,max,maxy]

   Parameters:

      p_input - SDO_GEOMETRY
      p_output_srid - Optional SRID to transform geometry before conversion.
      p_prune_number - Optional length to truncate precision of ordinates.

   Returns:

      CLOB of JSON array of four bbox ordinates 

   */
   FUNCTION sdo2bbox(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.srid2geojson_crs

   Function to convert Oracle Spatial srid into GeoJSON CRS object.

   Parameters:

      p_input - Oracle Spatial srid.
      p_pretty_print - Optional JSON formatter.

   Returns:

      CLOB of JSON CRS object 

   */
   FUNCTION srid2geojson_crs(
       p_input            IN  NUMBER
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.sdo2geojson_feature

   Function to convert SDO_GEOMETRY into a GeoJSON feature object.

   Parameters:

      p_input - SDO_GEOMETRY
      p_pretty_print - Optional JSON formatter.
      p_2d_flag - Optional TRUE/FALSE flag to remove 3rd and 4th dimensions.
      p_output_srid - Optional SRID to transform geometry before conversion.
      p_prune_number - Optional length to truncate precision of ordinates.
      p_add_crs - Optional TRUE/FALSE flag to add crs element.
      p_add_bbox - Optional TRUE/FALSE flag to add bbox element.
      p_properties - Optional properties to add to the output.

   Returns:

      CLOB of GeoJSON feature object
      
   Notes:
   
   -  Leave pretty print value NULL to output compact JSON.  Use zero for 
      pretty print formatting.  Larger values will continually indent the JSON 
      three spaces to the right.
      
   -  Properties must be provided as valid CLOB of GeoJSON properties array.

   */
   FUNCTION sdo2geojson_feature(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_add_crs          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_add_bbox         IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_properties       IN  CLOB     DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.fastname

   Utility function to format a json name attribute.

   Parameters:

      p_name - name for JSON attribute.
      p_pretty_print - Optional JSON formatter.

   Returns:

      VARCHAR2 snippet for JSON attribute name

   */
   FUNCTION fastname(
       p_name             IN  VARCHAR2
      ,p_pretty_print     IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.json_format

   Utility function to format a json name attribute.

   Parameters:

      p_input - value to format as JSON.
      p_quote_strings - Optional TRUE/FALSE flag whether to quote the JSON value.

   Returns:

      VARCHAR2 snippet for JSON attribute name.
      
   Notes:
   
   -  Input values may be VARCHAR2, NUMBER, DATE or CLOB.

   */
   FUNCTION json_format(
       p_input            IN  VARCHAR2
      ,p_quote_strings    IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN VARCHAR2;
   
   FUNCTION json_format(
       p_input            IN  NUMBER
      ,p_quote_strings    IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN VARCHAR2;
   
   FUNCTION json_format(
       p_input            IN  DATE
      ,p_quote_strings    IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN VARCHAR2;
   
   FUNCTION json_format(
       p_input            IN  CLOB
      ,p_quote_strings    IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.value2json

   Utility function to format a json named attribute.

   Parameters:

      p_name - JSON attribute name
      p_input - value to format as JSON.
      p_pretty_print - Optional JSON formatter.

   Returns:

      CLOB of JSON attribute.
      
   Notes:
   
   - Input values may be VARCHAR2, NUMBER, DATE, CLOB,
     MDSYS.SDO_STRING2_ARRAY or MDSYS.SDO_NUMBER_ARRAY.

   */
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  VARCHAR2
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  NUMBER
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  DATE
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  CLOB
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  MDSYS.SDO_STRING2_ARRAY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  MDSYS.SDO_NUMBER_ARRAY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.formatted2json

   Utility function to wrap a preformatted JSON value with an attribute name.

   Parameters:

      p_name - JSON attribute name
      p_input - JSON value (preformatted as proper JSON).
      p_pretty_print - Optional JSON formatter.

   Returns:

      CLOB of JSON attribute.

   */
   FUNCTION formatted2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  CLOB
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.empty_scalar2json

   Utility function to create a null JSON attribute.

   Parameters:

      p_name - JSON attribute name
      p_comma_flag - optional TRUE/FALSE flag to add a trailing comma to results.
      p_pretty_print - Optional JSON formatter.

   Returns:

      VARCHAR2 of null JSON attribute.
      
   */
   FUNCTION empty_scalar2json(
       p_name             IN  VARCHAR2
      ,p_comma_flag       IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_json_main.empty_scalar2json

   Utility function to create an empty JSON array attribute.

   Parameters:

      p_name - JSON attribute name
      p_comma_flag - optional TRUE/FALSE flag to add a trailing comma to results.
      p_pretty_print - Optional JSON formatter.

   Returns:

      VARCHAR2 of null JSON attribute.
      
   */
   FUNCTION empty_array2json(
       p_name             IN  VARCHAR2
      ,p_comma_flag       IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN VARCHAR2;
   
END dz_json_main;
/

GRANT EXECUTE ON dz_json_main TO public;

