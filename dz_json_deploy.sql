
--*************************--
PROMPT sqlplus_header.sql;

WHENEVER SQLERROR EXIT -99;
WHENEVER OSERROR  EXIT -98;
SET DEFINE OFF;



--*************************--
PROMPT DZ_JSON_UTIL.pks;

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
   
END dz_json_util;
/

GRANT EXECUTE ON dz_json_util TO PUBLIC;


--*************************--
PROMPT DZ_JSON_UTIL.pkb;

CREATE OR REPLACE PACKAGE BODY dz_json_util
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN  VARCHAR2
      ,p_regex            IN  VARCHAR2
      ,p_match            IN  VARCHAR2 DEFAULT NULL
      ,p_end              IN  NUMBER   DEFAULT 0
      ,p_trim             IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC 
   AS
      int_delim      PLS_INTEGER;
      int_position   PLS_INTEGER := 1;
      int_counter    PLS_INTEGER := 1;
      ary_output     MDSYS.SDO_STRING2_ARRAY;
      num_end        NUMBER      := p_end;
      str_trim       VARCHAR2(5 Char) := UPPER(p_trim);
      
      FUNCTION trim_varray(
         p_input            IN MDSYS.SDO_STRING2_ARRAY
      ) RETURN MDSYS.SDO_STRING2_ARRAY
      AS
         ary_output MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY();
         int_index  PLS_INTEGER := 1;
         str_check  VARCHAR2(4000 Char);
         
      BEGIN

         --------------------------------------------------------------------------
         -- Step 10
         -- Exit if input is empty
         --------------------------------------------------------------------------
         IF p_input IS NULL
         OR p_input.COUNT = 0
         THEN
            RETURN ary_output;
            
         END IF;

         --------------------------------------------------------------------------
         -- Step 20
         -- Trim the strings removing anything utterly trimmed away
         --------------------------------------------------------------------------
         FOR i IN 1 .. p_input.COUNT
         LOOP
            str_check := TRIM(p_input(i));
            
            IF str_check IS NULL
            OR str_check = ''
            THEN
               NULL;
               
            ELSE
               ary_output.EXTEND(1);
               ary_output(int_index) := str_check;
               int_index := int_index + 1;
               
            END IF;

         END LOOP;

         --------------------------------------------------------------------------
         -- Step 10
         -- Return the results
         --------------------------------------------------------------------------
         RETURN ary_output;

      END trim_varray;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Create the output array and check parameters
      --------------------------------------------------------------------------
      ary_output := MDSYS.SDO_STRING2_ARRAY();

      IF str_trim IS NULL
      THEN
         str_trim := 'FALSE';
         
      ELSIF str_trim NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      IF num_end IS NULL
      THEN
         num_end := 0;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Exit early if input is empty
      --------------------------------------------------------------------------
      IF p_str IS NULL
      OR p_str = ''
      THEN
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Account for weird instance of pure character breaking
      --------------------------------------------------------------------------
      IF p_regex IS NULL
      OR p_regex = ''
      THEN
         FOR i IN 1 .. LENGTH(p_str)
         LOOP
            ary_output.EXTEND(1);
            ary_output(i) := SUBSTR(p_str,i,1);
            
         END LOOP;
         
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Break string using the usual REGEXP functions
      --------------------------------------------------------------------------
      LOOP
         EXIT WHEN int_position = 0;
         int_delim  := REGEXP_INSTR(p_str,p_regex,int_position,1,0,p_match);
         
         IF  int_delim = 0
         THEN
            -- no more matches found
            ary_output.EXTEND(1);
            ary_output(int_counter) := SUBSTR(p_str,int_position);
            int_position  := 0;
            
         ELSE
            IF int_counter = num_end
            THEN
               -- take the rest as is
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position);
               int_position  := 0;
               
            ELSE
               --dbms_output.put_line(ary_output.COUNT);
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position,int_delim-int_position);
               int_counter := int_counter + 1;
               int_position := REGEXP_INSTR(p_str,p_regex,int_position,1,1,p_match);
               
            END IF;
            
         END IF;
         
      END LOOP;

      --------------------------------------------------------------------------
      -- Step 50
      -- Trim results if so desired
      --------------------------------------------------------------------------
      IF str_trim = 'TRUE'
      THEN
         RETURN trim_varray(
            p_input => ary_output
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 60
      -- Cough out the results
      --------------------------------------------------------------------------
      RETURN ary_output;
      
   END gz_split;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN VARCHAR2
      ,p_null_replacement IN NUMBER DEFAULT NULL
   ) RETURN NUMBER
   AS
   BEGIN
      RETURN TO_NUMBER(
         REPLACE(
            REPLACE(
               p_input,
               CHR(10),
               ''
            ),
            CHR(13),
            ''
         ) 
      );
      
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         RETURN p_null_replacement;
         
   END safe_to_number;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION strings2numbers(
      p_input            IN MDSYS.SDO_STRING2_ARRAY
   ) RETURN MDSYS.SDO_NUMBER_ARRAY
   AS
      ary_output MDSYS.SDO_NUMBER_ARRAY := MDSYS.SDO_NUMBER_ARRAY();
      num_tester NUMBER;
      int_index  PLS_INTEGER := 1;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Exit if input is empty
      --------------------------------------------------------------------------
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Convert anything that is a valid number to a number, dump the rest
      --------------------------------------------------------------------------
      FOR i IN 1 .. p_input.COUNT
      LOOP
         IF p_input(i) IS NOT NULL
         THEN
            num_tester := safe_to_number(
               p_input => p_input(i)
            );
            
            IF num_tester IS NOT NULL
            THEN
               ary_output.EXTEND();
               ary_output(int_index) := num_tester;
               int_index := int_index + 1;
               
            END IF;
            
         END IF;
         
      END LOOP;

      RETURN ary_output;

   END strings2numbers;

   ----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION true_point(
      p_input      IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
   BEGIN

      IF p_input.SDO_POINT IS NOT NULL
      THEN
         RETURN p_input;
         
      END IF;

      IF p_input.get_gtype() = 1
      THEN
         IF p_input.get_dims() = 2
         THEN
            RETURN MDSYS.SDO_GEOMETRY(
                p_input.SDO_GTYPE
               ,p_input.SDO_SRID
               ,MDSYS.SDO_POINT_TYPE(
                   p_input.SDO_ORDINATES(1)
                  ,p_input.SDO_ORDINATES(2)
                  ,NULL
                )
               ,NULL
               ,NULL
            );
            
         ELSIF p_input.get_dims() = 3
         THEN
            RETURN MDSYS.SDO_GEOMETRY(
                p_input.SDO_GTYPE
               ,p_input.SDO_SRID
               ,MDSYS.SDO_POINT_TYPE(
                    p_input.SDO_ORDINATES(1)
                   ,p_input.SDO_ORDINATES(2)
                   ,p_input.SDO_ORDINATES(3)
                )
               ,NULL
               ,NULL
            );
            
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'function true_point can only work on 2 and 3 dimensional points - dims=' || p_input.get_dims() || ' '
            );
            
         END IF;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'function true_point can only work on point geometries'
         );
         
      END IF;
      
   END true_point;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION downsize_2d(
      p_input   IN MDSYS.SDO_GEOMETRY
   ) RETURN MDSYS.SDO_GEOMETRY
   -- Originally taken from
   -- Ravikanth Kothuri, Albert Godfrind, Euro Beinat 
   -- Pro Oracle Spatial for Oracle Database 11g
   AS
      geom_2d       MDSYS.SDO_GEOMETRY;
      dim_count     PLS_INTEGER;
      gtype         PLS_INTEGER;
      n_points      PLS_INTEGER;
      n_ordinates   PLS_INTEGER;
      i             PLS_INTEGER;
      j             PLS_INTEGER;
      k             PLS_INTEGER;
      offset        PLS_INTEGER;
      
   BEGIN

      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      IF LENGTH(p_input.SDO_GTYPE) = 4
      THEN
         dim_count := p_input.get_dims();
         gtype     := p_input.get_gtype();
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            , 'Unable to determine dimensionality from gtype'
         );
         
      END IF;

      IF dim_count = 2
      THEN
         RETURN p_input;
         
      END IF;

      geom_2d := MDSYS.SDO_GEOMETRY(
          2000 + gtype
         ,p_input.SDO_SRID
         ,p_input.SDO_POINT
         ,MDSYS.SDO_ELEM_INFO_ARRAY()
         ,MDSYS.SDO_ORDINATE_ARRAY()
      );

      IF geom_2d.SDO_POINT IS NOT NULL
      THEN
         geom_2d.SDO_POINT.Z   := NULL;
         geom_2d.SDO_ELEM_INFO := NULL;
         geom_2d.SDO_ORDINATES := NULL;
         
      ELSE
         n_points    := p_input.SDO_ORDINATES.COUNT / dim_count;
         n_ordinates := n_points * 2;
         geom_2d.SDO_ORDINATES.EXTEND(n_ordinates);
         j := p_input.SDO_ORDINATES.FIRST;
         k := 1;
         FOR i IN 1 .. n_points
         LOOP
            geom_2d.SDO_ORDINATES(k) := p_input.SDO_ORDINATES(j);
            geom_2d.SDO_ORDINATES(k + 1) := p_input.SDO_ORDINATES(j + 1);
            j := j + dim_count;
            k := k + 2;
         
         END LOOP;

         geom_2d.SDO_ELEM_INFO := p_input.SDO_ELEM_INFO;

         i := geom_2d.SDO_ELEM_INFO.FIRST;
         WHILE i < geom_2d.SDO_ELEM_INFO.LAST
         LOOP
            offset := geom_2d.SDO_ELEM_INFO(i);
            geom_2d.SDO_ELEM_INFO(i) := (offset - 1) / dim_count * 2 + 1;
            i := i + 3;
            
         END LOOP;

      END IF;

      IF geom_2d.SDO_GTYPE = 2001
      THEN
         RETURN true_point(
            p_input => geom_2d
         );
         
      ELSE
         RETURN geom_2d;
         
      END IF;

   END downsize_2d;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN NUMBER
   AS
   BEGIN
      
      IF p_trunc IS NULL
      THEN
         RETURN p_input;
         
      END IF;
      
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      RETURN TRUNC(p_input,p_trunc);
      
   END prune_number;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_varchar2(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2
   AS
   BEGIN
      RETURN TO_CHAR(
         prune_number(
             p_input => p_input
            ,p_trunc => p_trunc
         )
      );
      
   END prune_number_varchar2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prune_number_clob(
       p_input       IN  NUMBER
      ,p_trunc       IN  NUMBER DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
      RETURN TO_CLOB(
         prune_number(
             p_input => p_input
            ,p_trunc => p_trunc
         )
      );
      
   END prune_number_clob;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION indent(
       p_level      IN NUMBER
      ,p_amount     IN VARCHAR2 DEFAULT '   '
   ) RETURN VARCHAR2
   AS
      str_output VARCHAR2(4000 Char) := '';
      
   BEGIN
   
      IF  p_level IS NOT NULL
      AND p_level > 0
      THEN
         FOR i IN 1 .. p_level
         LOOP
            str_output := str_output || p_amount;
            
         END LOOP;
         
         RETURN str_output;
         
      ELSE
         RETURN '';
         
      END IF;
      
   END indent;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION pretty(
       p_input      IN CLOB
      ,p_level      IN NUMBER
      ,p_amount     IN VARCHAR2 DEFAULT '   '
      ,p_linefeed   IN VARCHAR2 DEFAULT CHR(10)
   ) RETURN CLOB
   AS
      str_amount   VARCHAR2(4000 Char) := p_amount;
      str_linefeed VARCHAR2(2 Char)    := p_linefeed;
      
   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Process Incoming Parameters
      --------------------------------------------------------------------------
      IF p_amount IS NULL
      THEN
         str_amount := '   ';
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- If input is NULL, then do nothing
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Return indented and line fed results
      --------------------------------------------------------------------------
      IF p_level IS NULL
      THEN
         RETURN p_input;
         
      ELSIF p_level = -1
      THEN
         RETURN p_input || TO_CLOB(str_linefeed);
         
      ELSE
         RETURN TO_CLOB(indent(p_level,str_amount)) || p_input || TO_CLOB(str_linefeed);
         
      END IF;

   END pretty;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input      IN OUT MDSYS.SDO_NUMBER_ARRAY
      ,p_value      IN     MDSYS.SDO_NUMBER_ARRAY
      ,p_unique     IN     VARCHAR2 DEFAULT 'FALSE'
   )
   AS
   BEGIN
   
      FOR i IN 1 .. p_value.COUNT
      LOOP
         append2(
             p_input   => p_input
            ,p_value   => p_value(i)
            ,p_unique  => p_unique
         );
         
      END LOOP;
      
   END append2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input      IN OUT MDSYS.SDO_NUMBER_ARRAY
      ,p_value      IN     NUMBER
      ,p_unique     IN     VARCHAR2 DEFAULT 'FALSE'
   )
   AS
      boo_check   BOOLEAN;
      num_index   PLS_INTEGER;
      str_unique  VARCHAR2(5 Char);
      
   BEGIN
   
      IF p_unique IS NULL
      THEN
         str_unique := 'FALSE';
         
      ELSIF UPPER(p_unique) IN ('FALSE','TRUE')
      THEN
         str_unique := UPPER(p_unique);
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      IF p_input IS NULL
      THEN
         p_input := MDSYS.SDO_NUMBER_ARRAY();
         
      END IF;

      IF p_input.COUNT > 0
      THEN
         IF str_unique = 'TRUE'
         THEN
            boo_check := FALSE;
            
            FOR i IN 1 .. p_input.COUNT
            LOOP
               IF p_value = p_input(i)
               THEN
                  boo_check := TRUE;
                  
               END IF;
               
            END LOOP;

            IF boo_check = TRUE
            THEN
               RETURN;
               
            END IF;

         END IF;

      END IF;

      num_index := p_input.COUNT + 1;
      p_input.EXTEND(1);
      p_input(num_index) := p_value;

   END append2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input      IN OUT MDSYS.SDO_STRING2_ARRAY
      ,p_value      IN     MDSYS.SDO_STRING2_ARRAY
      ,p_unique     IN     VARCHAR2 DEFAULT 'FALSE'
   )
   AS
   BEGIN
   
      FOR i IN 1 .. p_value.COUNT
      LOOP
         append2(
            p_input   => p_input,
            p_value   => p_value(i),
            p_unique  => p_unique
         );
         
      END LOOP;
      
   END append2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE append2(
       p_input      IN OUT MDSYS.SDO_STRING2_ARRAY
      ,p_value      IN     VARCHAR2
      ,p_unique     IN     VARCHAR2 DEFAULT 'FALSE'
   )
   AS
      boo_check   BOOLEAN;
      num_index   PLS_INTEGER;
      str_unique  VARCHAR2(5 Char);
      
   BEGIN
   
      IF p_unique IS NULL
      THEN
         str_unique := 'FALSE';
         
      ELSIF UPPER(p_unique) IN ('FALSE','TRUE')
      THEN
         str_unique := UPPER(p_unique);
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      IF p_input IS NULL
      THEN
         p_input := MDSYS.SDO_STRING2_ARRAY();
         
      END IF;

      IF p_input.COUNT > 0
      THEN
         IF str_unique = 'TRUE'
         THEN
            boo_check := FALSE;
            
            FOR i IN 1 .. p_input.COUNT
            LOOP
               IF p_value = p_input(i)
               THEN
                  boo_check := TRUE;
                  
               END IF;
               
            END LOOP;

            IF boo_check = TRUE
            THEN
               RETURN;
               
            END IF;
            
         END IF;

      END IF;

      num_index := p_input.COUNT + 1;
      p_input.EXTEND(1);
      p_input(num_index) := p_value;

   END append2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION a_in_b(
       p_input_a          IN  NUMBER
      ,p_input_b          IN  MDSYS.SDO_NUMBER_ARRAY
   ) RETURN VARCHAR2
   AS
      boo_check BOOLEAN := FALSE;
      
   BEGIN
   
      IF p_input_a IS NULL
      THEN
         RETURN 'FALSE';
         
      END IF;
      
      IF p_input_b IS NULL
      OR p_input_b.COUNT = 0
      THEN
         RETURN 'FALSE';
         
      END IF;
      
      FOR i IN 1 .. p_input_b.COUNT
      LOOP
         IF p_input_a = p_input_b(i)
         THEN
            boo_check := TRUE;
            EXIT;
            
         END IF;
         
      END LOOP;
      
      IF boo_check = TRUE
      THEN
         RETURN 'TRUE';
         
      ELSE
         RETURN 'FALSE';
         
      END IF;
      
   END a_in_b;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION a_in_b(
       p_input_a          IN MDSYS.SDO_NUMBER_ARRAY
      ,p_input_b          IN MDSYS.SDO_NUMBER_ARRAY
   ) RETURN VARCHAR2
   AS
   BEGIN
   
      IF p_input_a IS NULL
      THEN
         RETURN 'FALSE';
         
      END IF;

      IF p_input_b IS NULL
      OR p_input_b.COUNT = 0
      THEN
         RETURN 'FALSE';
         
      END IF;

      FOR i IN 1 .. p_input_a.COUNT
      LOOP
         IF a_in_b(p_input_a(i),p_input_b) = 'TRUE'
         THEN
            RETURN 'TRUE';
            
         END IF;

      END LOOP;

      RETURN 'FALSE';

   END a_in_b;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION a_in_b(
       p_input_a          IN VARCHAR2
      ,p_input_b          IN MDSYS.SDO_STRING2_ARRAY
   ) RETURN VARCHAR2
   AS
      boo_check BOOLEAN := FALSE;
      
   BEGIN
   
      IF p_input_a IS NULL
      THEN
         RETURN 'FALSE';
         
      END IF;

      IF p_input_b IS NULL
      OR p_input_b.COUNT = 0
      THEN
         RETURN 'FALSE';
         
      END IF;

      FOR i IN 1 .. p_input_b.COUNT
      LOOP
         IF p_input_a = p_input_b(i)
         THEN
            boo_check := TRUE;
            EXIT;
            
         END IF;
         
      END LOOP;

      IF boo_check = TRUE
      THEN
         RETURN 'TRUE';
         
      ELSE
         RETURN 'FALSE';
         
      END IF;
      
   END a_in_b;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION a_in_b(
       p_input_a          IN MDSYS.SDO_STRING2_ARRAY
      ,p_input_b          IN MDSYS.SDO_STRING2_ARRAY
   ) RETURN VARCHAR2
   AS
   BEGIN

      IF p_input_a IS NULL
      OR p_input_a.COUNT = 0
      THEN
         RETURN 'FALSE';
         
      END IF;

      IF p_input_b IS NULL
      OR p_input_b.COUNT = 0
      THEN
         RETURN 'FALSE';
         
      END IF;

      FOR i IN 1 .. p_input_a.COUNT
      LOOP
         IF a_in_b(p_input_a(i),p_input_b) = 'FALSE'
         THEN
            RETURN 'FALSE';
            
         END IF;
         
      END LOOP;

      RETURN 'TRUE';

   END a_in_b;

END dz_json_util;
/


--*************************--
PROMPT DZ_JSON_MAIN.pks;

CREATE OR REPLACE PACKAGE dz_json_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_JSON
     
   - Build ID: 4
   - TFS Change Set: 8323
   
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


--*************************--
PROMPT DZ_JSON_MAIN.pkb;

CREATE OR REPLACE PACKAGE BODY dz_json_main 
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION transform(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output MDSYS.SDO_GEOMETRY;
      
   BEGIN
      IF p_input IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      IF p_output_srid IS NULL
      THEN
         RETURN p_input;
         
      END IF;
   
      IF p_output_srid <> p_input.SDO_SRID
      THEN
         -- Try to avoid transforming over equal SRIDs
         IF  p_output_srid IN (4269,8265)
         AND p_input.SDO_SRID IN (4269,8265)
         THEN
            RETURN p_input;
         
         ELSIF  p_output_srid IN (4326,8307)
         AND p_input.SDO_SRID IN (4326,8307)
         THEN
            RETURN p_input;
            
         ELSIF  p_output_srid IN (3857,3785)
         AND p_input.SDO_SRID IN (3857,3785)
         THEN
            RETURN p_input;
            
         ELSE
            sdo_output := MDSYS.SDO_CS.TRANSFORM(p_input,p_output_srid);
            RETURN sdo_output;
            
         END IF;
         
      END IF;
      
      RETURN p_input;
      
   END transform;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION point2coords(
       p_input            IN  MDSYS.SDO_POINT_TYPE
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      str_output VARCHAR2(4000 Char) := '';
      
   BEGIN
   
      str_output := str_output || '[' || dz_json_util.prune_number(
          p_input => p_input.x
         ,p_trunc => p_prune_number
      ) || ',' || dz_json_util.prune_number(
          p_input => p_input.y
         ,p_trunc => p_prune_number
      );
                 
      IF p_input.z IS NOT NULL
      AND p_2d_flag = 'FALSE'
      THEN
         str_output := str_output || ',' || dz_json_util.prune_number(
             p_input => p_input.z
            ,p_trunc => p_prune_number
         );
         
      END IF;
      
      str_output := str_output || ']';
      
      RETURN TO_CLOB(str_output);   
      
   END point2coords;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION point2coords(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_dims   PLS_INTEGER;
      int_gtyp   PLS_INTEGER;
      str_output VARCHAR2(4000 Char) := '';
      
   BEGIN
   
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      
      IF int_gtyp != 1
      THEN
         RAISE_APPLICATION_ERROR(-20001,'input sdo must be point');
         
      END IF;
      
      IF p_input.SDO_POINT IS NOT NULL
      THEN
         RETURN point2coords(
             p_input        => p_input.SDO_POINT
            ,p_2d_flag      => p_2d_flag
            ,p_prune_number => p_prune_number
         );
         
      END IF;
      
      str_output := str_output || '[' || dz_json_util.prune_number(
          p_input => p_input.SDO_ORDINATES(1)
         ,p_trunc => p_prune_number
      ) || ',' || dz_json_util.prune_number(
          p_input => p_input.SDO_ORDINATES(2)
         ,p_trunc => p_prune_number
      );
      
      IF  int_dims > 2
      AND p_2d_flag = 'FALSE'
      THEN
         str_output := str_output || ',' || dz_json_util.prune_number(p_input.SDO_ORDINATES(3),16);
         
      END IF;
      
      IF  int_dims > 3
      AND p_2d_flag = 'FALSE'
      THEN
         str_output := str_output || ',' || dz_json_util.prune_number(p_input.SDO_ORDINATES(4),16);
         
      END IF;
      
      str_output := str_output || ']';
      
      RETURN TO_CLOB(str_output);
      
   END point2coords;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdoords2coords(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_start            IN  NUMBER   DEFAULT 1
      ,p_stop             IN  NUMBER   DEFAULT NULL
      ,p_inter            IN  NUMBER   DEFAULT 1
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_output  CLOB;
      clb_vertice CLOB;
      int_start   PLS_INTEGER;
      int_stop    PLS_INTEGER;
      int_counter PLS_INTEGER;
      int_dims    PLS_INTEGER;
      int_lrs     PLS_INTEGER;
      str_pad     VARCHAR2(1 Char);
      boo_first   BOOLEAN;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims := p_input.get_dims();
      int_lrs  := p_input.get_lrs_dim();
      
      int_start := p_start;
      IF p_stop IS NULL
      THEN
         int_stop := p_input.SDO_ORDINATES.COUNT;
         
      ELSE
         int_stop := p_stop;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left brace
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output := dz_json_util.pretty('[',NULL);
         str_pad := NULL;
         
      ELSE
         clb_output := dz_json_util.pretty('[',-1);
         str_pad := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Generate the ordinate list if simple geometry
      --------------------------------------------------------------------------
      IF p_inter = 1
      THEN
         int_counter := int_start;
         boo_first := TRUE;
         
         WHILE int_counter <= int_stop
         LOOP
            clb_vertice := TO_CLOB(
                '[' || dz_json_util.prune_number(
                    p_input => p_input.SDO_ORDINATES(int_counter)
                   ,p_trunc => p_prune_number
                )
            );
            
            int_counter := int_counter + 1;
            
            clb_vertice := clb_vertice || TO_CLOB(
                ',' || dz_json_util.prune_number(
                    p_input => p_input.SDO_ORDINATES(int_counter)
                   ,p_trunc => p_prune_number
                )
            );
            
            int_counter := int_counter + 1;

            IF int_dims > 2
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_vertice := clb_vertice || TO_CLOB(
                      ',' || dz_json_util.prune_number(
                          p_input => p_input.SDO_ORDINATES(int_counter)
                         ,p_trunc => p_prune_number
                      )
                  );
                  
               END IF;
               
               int_counter := int_counter + 1;
               
            END IF;
         
            IF int_dims > 3
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_vertice := clb_vertice || TO_CLOB(
                      ',' || dz_json_util.prune_number(
                          p_input => p_input.SDO_ORDINATES(int_counter)
                         ,p_trunc => p_prune_number
                      )
                  );
                  
               END IF;
               
               int_counter := int_counter + 1;
               
            END IF;
            
            clb_vertice := clb_vertice || TO_CLOB(']');
            
            IF boo_first
            THEN
               clb_output := clb_output || dz_json_util.pretty(
                   str_pad || clb_vertice
                  ,p_pretty_print + 1
               );
               boo_first := FALSE;
               
            ELSE
               clb_output := clb_output || dz_json_util.pretty(
                   ',' || clb_vertice
                  ,p_pretty_print + 1
               );
                
            END IF;
         
         END LOOP;
         
      --------------------------------------------------------------------------
      -- Step 40
      -- Generate the ordinate list if optimized rectangle
      --------------------------------------------------------------------------
      ELSIF p_inter = 3
      THEN
         IF int_dims != (p_stop - p_start + 1)/2
         THEN
            RAISE_APPLICATION_ERROR(
                -20001
               ,'extract etype 3 from geometry'
            );
            
         END IF;
         
         IF int_dims = 2
         THEN
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                str_pad || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            ) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            ) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
  
         ELSIF int_dims = 3
         THEN
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(5)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(6)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(5)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(6)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
         ELSIF int_dims = 4
         THEN
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               ) || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(4)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(5)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               ) || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(4)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(5)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(6)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(7)
                  ,p_trunc => p_prune_number
               ) || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(8)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(6)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(7)
                  ,p_trunc => p_prune_number
               ) || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(8)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            );
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               ) || ',' || dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(4)
                  ,p_trunc => p_prune_number
               );
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
         END IF;
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'no code for interpretation ' || p_inter
         );
         
      END IF;
      
      RETURN clb_output || dz_json_util.pretty(
          ']'
         ,p_pretty_print,NULL,NULL
      );
      
   END sdoords2coords;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION polygon2coords(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_dims    PLS_INTEGER;
      int_gtyp    PLS_INTEGER;
      int_counter PLS_INTEGER;
      clb_output  CLOB := TO_CLOB('');
      int_offset  PLS_INTEGER;
      int_etype   PLS_INTEGER;
      int_inter   PLS_INTEGER;
      int_start   PLS_INTEGER;
      int_stop    PLS_INTEGER;
      str_pad     VARCHAR2(1 Char);
      boo_check   BOOLEAN;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      
      IF int_gtyp != 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be polygon'
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left brace
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output := dz_json_util.pretty('[',NULL);
         str_pad := NULL;
         
      ELSE
         clb_output := dz_json_util.pretty('[',-1);
         str_pad := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Spin through ordinates and sort into rings
      --------------------------------------------------------------------------
      boo_check := TRUE;
      int_counter := 1;
      WHILE int_counter <= p_input.SDO_ELEM_INFO.COUNT
      LOOP
         int_offset  := p_input.SDO_ELEM_INFO(int_counter);
         int_counter := int_counter + 1;
         int_etype   := p_input.SDO_ELEM_INFO(int_counter);
         int_counter := int_counter + 1;
         int_inter   := p_input.SDO_ELEM_INFO(int_counter);
         int_counter := int_counter + 1;
         
         int_start   := int_offset;
         IF int_counter > p_input.SDO_ELEM_INFO.COUNT
         THEN
            int_stop := NULL;
         
         ELSE
            int_stop := p_input.SDO_ELEM_INFO(int_counter) - 1;
            
         END IF;
         
         IF int_etype IN (1003,2003)
         THEN
            IF boo_check
            THEN
               clb_output := clb_output || dz_json_util.pretty(
                   p_input => str_pad || sdoords2coords(
                       p_input        => p_input
                      ,p_start        => int_start
                      ,p_stop         => int_stop
                      ,p_inter        => int_inter
                      ,p_pretty_print => p_pretty_print +1
                      ,p_2d_flag      => p_2d_flag
                      ,p_prune_number => p_prune_number
                   )
                  ,p_level => p_pretty_print + 1
               );
               boo_check := FALSE;
               
            ELSE
               clb_output := clb_output || dz_json_util.pretty(
                   p_input => ',' || sdoords2coords(
                       p_input        => p_input
                      ,p_start        => int_start
                      ,p_stop         => int_stop
                      ,p_inter        => int_inter
                      ,p_pretty_print => p_pretty_print +1
                      ,p_2d_flag      => p_2d_flag
                      ,p_prune_number => p_prune_number
                   )
                  ,p_level => p_pretty_print + 1
               );
            
            END IF;   
                 
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'no code for etype ' || int_etype
            );
         
         END IF;  
          
      END LOOP;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add the right brace
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          ']'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
      
   END polygon2coords;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION point2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_dims    PLS_INTEGER;
      int_gtyp    PLS_INTEGER;
      clb_output  CLOB := '';
      str_pad     VARCHAR2(1 Char);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      
      IF int_gtyp <> 1
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be point'
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output := dz_json_util.pretty('{',NULL);
         str_pad := NULL;
         
      ELSE
         clb_output := dz_json_util.pretty('{',-1);
         str_pad := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add type and coordinates attribute
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'Point'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      ) || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'coordinates'
             ,point2coords(
                  p_input        => p_input
                 ,p_2d_flag      => p_2d_flag
                 ,p_prune_number => p_prune_number
              )
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add the right bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
      
   END point2geojson;  
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION pointcluster2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_dims       PLS_INTEGER;
      int_gtyp       PLS_INTEGER;
      int_counter    PLS_INTEGER;
      int_stop       PLS_INTEGER;
      clb_output     CLOB;
      clb_ordinates  CLOB;
      clb_vertice    CLOB;
      str_pad        VARCHAR2(1 Char);
      boo_first      BOOLEAN;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      
      IF int_gtyp <> 5
      AND p_input.SDO_ELEM_INFO.COUNT <> 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be point cluster'
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output    := dz_json_util.pretty('{',NULL);
         clb_ordinates := dz_json_util.pretty('[',NULL);
         str_pad       := NULL;
         
      ELSE
         clb_output    := dz_json_util.pretty('{',-1);
         clb_ordinates := dz_json_util.pretty('[',-1);
         str_pad       := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Generate the ordinates
      --------------------------------------------------------------------------
      int_stop := p_input.SDO_ORDINATES.COUNT;
      int_counter := 1;
      boo_first := TRUE;
      
      WHILE int_counter <= int_stop
      LOOP       
         clb_vertice := TO_CLOB(
            '[' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(int_counter)
               ,p_trunc => p_prune_number
            )
         );
         int_counter := int_counter + 1;
            
         clb_vertice  := clb_vertice || TO_CLOB(
            ',' || dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(int_counter)
               ,p_trunc => p_prune_number
            )
         );
         int_counter := int_counter + 1;

         IF int_dims > 2
         THEN
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || TO_CLOB(
                  ',' || dz_json_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(int_counter)
                     ,p_trunc => p_prune_number
                  )
               );
               
            END IF;
            
            int_counter := int_counter + 1;
         
         END IF;
         
         IF int_dims > 3
         THEN
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || TO_CLOB(
                  ',' || dz_json_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(int_counter)
                     ,p_trunc => p_prune_number
                  )
               );
               
            END IF;
            
            int_counter := int_counter + 1;

         END IF;
         
         clb_vertice := clb_vertice || TO_CLOB(']');
         
         IF boo_first
         THEN
            clb_ordinates := clb_ordinates || dz_json_util.pretty(
                str_pad || clb_vertice
               ,p_pretty_print + 2
            );
            boo_first := FALSE;
            
         ELSE
            clb_ordinates := clb_ordinates || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 2
            );
             
         END IF;
         
      END LOOP;
      
      clb_ordinates := clb_ordinates || dz_json_util.pretty(
          ']'
         ,p_pretty_print + 1,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add type and coordinates attribute
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'MultiPoint'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      ) || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'coordinates'
             ,clb_ordinates
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Add the right bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 60
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
         
   END pointcluster2geojson;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION line2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_dims    PLS_INTEGER;
      int_gtyp    PLS_INTEGER;
      int_lrs     PLS_INTEGER;
      clb_output  CLOB := TO_CLOB('');
      str_pad     VARCHAR2(1 Char);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      int_lrs  := p_input.get_lrs_dim();
      
      IF int_gtyp <> 2
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be line'
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output := dz_json_util.pretty('{',NULL);
         str_pad := NULL;
         
      ELSE
         clb_output := dz_json_util.pretty('{',-1);
         str_pad := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add type and coordinates attribute
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'LineString'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      ) || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'coordinates'
             ,sdoords2coords(
                 p_input        => p_input
                ,p_start        => 1
                ,p_stop         => NULL
                ,p_inter        => 1
                ,p_pretty_print => p_pretty_print + 1
                ,p_2d_flag      => p_2d_flag
                ,p_prune_number => p_prune_number
              )
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add the right bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
      
   END line2geojson;  
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION polygon2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_dims    PLS_INTEGER;
      int_gtyp    PLS_INTEGER;
      clb_output  CLOB := TO_CLOB('');
      str_pad     VARCHAR2(1 Char);
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims := p_input.get_dims();
      int_gtyp := p_input.get_gtype();
      
      IF int_gtyp != 3
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be polygon'
         );
         
      END IF;
                  
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output := dz_json_util.pretty('{',NULL);
         str_pad := NULL;
         
      ELSE
         clb_output := dz_json_util.pretty('{',-1);
         str_pad := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add type and coordinates attribute
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'Polygon'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      ) || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'coordinates'
             ,polygon2coords(
                  p_input        => p_input
                 ,p_pretty_print => p_pretty_print + 1
                 ,p_2d_flag      => p_2d_flag
                 ,p_prune_number => p_prune_number
              )
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add the right bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
      
   END polygon2geojson;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION multipoint2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_gtype     PLS_INTEGER;
      int_dims      PLS_INTEGER;
      int_index     PLS_INTEGER;
      clb_output    CLOB;
      clb_ordinates CLOB;
      str_pad       VARCHAR2(1 Char);
      boo_first     BOOLEAN;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims  := p_input.get_dims();
      int_gtype := p_input.get_gtype();
      
      IF int_gtype <> 5
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be multipoint'
         );
         
      END IF;
      
      int_index := MDSYS.SDO_UTIL.GETNUMELEM(p_input);
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output    := dz_json_util.pretty('{',NULL);
         clb_ordinates := dz_json_util.pretty('[',NULL);
         str_pad       := NULL;
         
      ELSE
         clb_output    := dz_json_util.pretty('{',-1);
         clb_ordinates := dz_json_util.pretty('[',-1);
         str_pad       := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Generate the ordinates
      --------------------------------------------------------------------------
      boo_first := TRUE;
      FOR i IN 1 .. int_index
      LOOP
         IF boo_first
         THEN
            clb_ordinates := clb_ordinates || dz_json_util.pretty(
                str_pad || point2coords(
                    p_input        => MDSYS.SDO_UTIL.EXTRACT(p_input,i)
                   ,p_2d_flag      => p_2d_flag
                   ,p_prune_number => p_prune_number
                )
               ,p_pretty_print + 2
            );
            boo_first := FALSE;
            
         ELSE
            clb_ordinates := clb_ordinates || dz_json_util.pretty(
                ',' || point2coords(
                    p_input        => MDSYS.SDO_UTIL.EXTRACT(p_input,i)
                   ,p_2d_flag      => p_2d_flag
                   ,p_prune_number => p_prune_number
                )
               ,p_pretty_print + 2
            );
            
         END IF;
         
      END LOOP;
      
      clb_ordinates := clb_ordinates || dz_json_util.pretty(
          ']'
         ,p_pretty_print + 1,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add type and coordinates attribute
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'MultiPoint'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      ) || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'coordinates'
             ,clb_ordinates
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add the right bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
      
      
   END multipoint2geojson;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION multiline2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_gtype     PLS_INTEGER;
      int_dims      PLS_INTEGER;
      int_index     PLS_INTEGER;
      clb_output    CLOB := TO_CLOB('');
      clb_ordinates CLOB;
      str_pad       VARCHAR2(1 Char);
      boo_first     BOOLEAN;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims  := p_input.get_dims();
      int_gtype := p_input.get_gtype();
      
      IF int_gtype != 6
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be multiline'
         );
         
      END IF;
      
      int_index := MDSYS.SDO_UTIL.GETNUMELEM(p_input);
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output    := dz_json_util.pretty('{',NULL);
         clb_ordinates := dz_json_util.pretty('[',NULL);
         str_pad       := NULL;
         
      ELSE
         clb_output    := dz_json_util.pretty('{',-1);
         clb_ordinates := dz_json_util.pretty('[',-1);
         str_pad       := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Generate the ordinates
      --------------------------------------------------------------------------
      boo_first := TRUE;
      FOR i IN 1 .. int_index
      LOOP
         IF boo_first
         THEN
            clb_ordinates := clb_ordinates || dz_json_util.pretty(
                str_pad || sdoords2coords(
                    p_input        => MDSYS.SDO_UTIL.EXTRACT(p_input,i)
                   ,p_start        => 1
                   ,p_stop         => NULL
                   ,p_inter        => 1
                   ,p_pretty_print => p_pretty_print + 2
                   ,p_2d_flag      => p_2d_flag
                   ,p_prune_number => p_prune_number
                )
               ,p_pretty_print + 2
            );
            boo_first := FALSE;
            
         ELSE
            clb_ordinates := clb_ordinates || dz_json_util.pretty(
                ',' || sdoords2coords(
                    p_input        => MDSYS.SDO_UTIL.EXTRACT(p_input,i)
                   ,p_start        => 1
                   ,p_stop         => NULL
                   ,p_inter        => 1
                   ,p_pretty_print => p_pretty_print + 2
                   ,p_2d_flag      => p_2d_flag
                   ,p_prune_number => p_prune_number
                )
               ,p_pretty_print + 2
            );
            
         END IF;
         
      END LOOP;
      
      clb_ordinates := clb_ordinates || dz_json_util.pretty(
          ']'
         ,p_pretty_print + 1,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add type and coordinates attribute
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'MultiLineString'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      ) || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'coordinates'
             ,clb_ordinates
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add the right bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;

   END multiline2geojson;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION multipolygon2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_gtype     PLS_INTEGER;
      int_dims      PLS_INTEGER;
      int_index     PLS_INTEGER;
      clb_output    CLOB := TO_CLOB('');
      clb_ordinates CLOB;
      str_pad       VARCHAR2(1 Char);
      boo_first     BOOLEAN;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims  := p_input.get_dims();
      int_gtype := p_input.get_gtype();
      
      IF int_gtype <> 7
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be multipolygon'
         );
         
      END IF;
      
      int_index := MDSYS.SDO_UTIL.GETNUMELEM(p_input);
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output    := dz_json_util.pretty('{',NULL);
         clb_ordinates := dz_json_util.pretty('[',NULL);
         str_pad       := NULL;
         
      ELSE
         clb_output    := dz_json_util.pretty('{',-1);
         clb_ordinates := dz_json_util.pretty('[',-1);
         str_pad       := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Generate the ordinates
      --------------------------------------------------------------------------
      boo_first := TRUE;
      FOR i IN 1 .. int_index
      LOOP
         IF boo_first
         THEN
            clb_ordinates := clb_ordinates || dz_json_util.pretty(
                str_pad || polygon2coords(
                    p_input        => MDSYS.SDO_UTIL.EXTRACT(p_input,i)
                   ,p_pretty_print => p_pretty_print + 2
                   ,p_2d_flag      => p_2d_flag
                   ,p_prune_number => p_prune_number
                )
               ,p_pretty_print + 2
            );
            boo_first := FALSE;
            
         ELSE
            clb_ordinates := clb_ordinates || dz_json_util.pretty(
                ',' || polygon2coords(
                    p_input        => MDSYS.SDO_UTIL.EXTRACT(p_input,i)
                   ,p_pretty_print => p_pretty_print + 2
                   ,p_2d_flag      => p_2d_flag
                   ,p_prune_number => p_prune_number
                )
               ,p_pretty_print + 2
            );
            
         END IF;
         
      END LOOP;
      
      clb_ordinates := clb_ordinates || dz_json_util.pretty(
          ']'
         ,p_pretty_print + 1,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add type and coordinates attribute
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'MultiPolygon'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      ) || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'coordinates'
             ,clb_ordinates
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add the right bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;

   END multipolygon2geojson;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION collection2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      int_gtype     PLS_INTEGER;
      int_dims      PLS_INTEGER;
      int_index     PLS_INTEGER;
      clb_output    CLOB := TO_CLOB('');
      clb_payload   CLOB;
      str_pad       VARCHAR2(1 Char);
      str_sep       VARCHAR2(1 Char);
      boo_first     BOOLEAN;
      sdo_part      MDSYS.SDO_GEOMETRY;
      int_part      PLS_INTEGER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      int_dims  := p_input.get_dims();
      int_gtype := p_input.get_gtype();
      
      IF int_gtype <> 4
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo must be collection'
         );
         
      END IF;
      
      int_index := MDSYS.SDO_UTIL.GETNUMELEM(p_input);
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output    := dz_json_util.pretty('{',NULL);
         clb_payload   := dz_json_util.pretty('[',NULL);
         str_pad       := NULL;
         
      ELSE
         clb_output    := dz_json_util.pretty('{',-1);
         clb_payload   := dz_json_util.pretty('[',-1);
         str_pad       := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Generate the ordinates
      --------------------------------------------------------------------------
      boo_first := TRUE;
      FOR i IN 1 .. int_index
      LOOP
         IF boo_first
         THEN
            str_sep := str_pad;
            boo_first := FALSE;
            
         ELSE
            str_sep := ',';
            
         END IF;
         
         sdo_part := MDSYS.SDO_UTIL.EXTRACT(p_input,i);
         int_part := sdo_part.get_gtype();
         
         IF int_part = 1
         THEN
            clb_payload := clb_payload || dz_json_util.pretty(
                str_sep || point2geojson(
                    p_input        => sdo_part
                   ,p_pretty_print => p_pretty_print + 2
                   ,p_2d_flag      => p_2d_flag
                   ,p_prune_number => p_prune_number
                )
               ,p_pretty_print + 2
            );
               
         ELSIF int_part = 2
         THEN
            clb_payload := clb_payload || dz_json_util.pretty(
                str_sep || line2geojson(
                    p_input        => sdo_part
                   ,p_pretty_print => p_pretty_print + 2
                   ,p_2d_flag      => p_2d_flag
                   ,p_prune_number => p_prune_number
                )
               ,p_pretty_print + 2
            );
               
         ELSIF int_part = 3
         THEN
            clb_payload := clb_payload || dz_json_util.pretty(
                str_sep || polygon2geojson(
                    p_input        => sdo_part
                   ,p_pretty_print => p_pretty_print + 2
                   ,p_2d_flag      => p_2d_flag
                   ,p_prune_number => p_prune_number
                )
               ,p_pretty_print + 2
            );
               
         ELSE
            RAISE_APPLICATION_ERROR(
                -20001
               ,'gtype is not simple'
            );
               
         END IF;
         
      END LOOP;
      
      clb_payload := clb_payload || dz_json_util.pretty(
          ']'
         ,p_pretty_print + 1,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add type and coordinates attribute
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'GeometryCollection'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      ) || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'geometries'
             ,clb_payload
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add the right bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;

   END collection2geojson;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION geojson2sdo(
       p_input            IN  CLOB
      ,p_srid             IN  NUMBER DEFAULT NULL
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      --- Stub for future development
   BEGIN
      RAISE_APPLICATION_ERROR(
          -20001
         ,'unimplemented'
      );
      
   END geojson2sdo;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2geojson(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      sdo_input     MDSYS.SDO_GEOMETRY := p_input;
      str_2d_flag   VARCHAR2(5 Char)  := UPPER(p_2d_flag);
      
      int_gtype     PLS_INTEGER;
      int_dims      PLS_INTEGER;
      int_lrs       PLS_INTEGER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------   
      IF sdo_input IS NULL
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'input sdo geometry is NULL'
         );
         
      END IF;
   
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'TRUE';
         
      ELSIF str_2d_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_2d_flag parameter can only be TRUE or FALSE'
         );
         
      END IF;
         
      --------------------------------------------------------------------------
      -- Step 20
      -- Transform if required
      --------------------------------------------------------------------------   
      IF p_output_srid IS NOT NULL
      AND p_output_srid != sdo_input.SDO_SRID
      THEN
         -- Try to avoid transforming over equal SRIDs
         IF  p_output_srid IN (4269,8265)
         AND sdo_input.SDO_SRID IN (4269,8265)
         THEN
            NULL;
            
         ELSIF  p_output_srid IN (4326,8307)
         AND sdo_input.SDO_SRID IN (4326,8307)
         THEN
            NULL;
            
         ELSIF  p_output_srid IN (3857,3785)
         AND sdo_input.SDO_SRID IN (3857,3785)
         THEN
            NULL;
            
         ELSE
            sdo_input := MDSYS.SDO_CS.TRANSFORM(sdo_input,p_output_srid);
            
         END IF;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Run the conversion
      --------------------------------------------------------------------------   
      int_gtype := sdo_input.get_gtype();
      int_dims  := sdo_input.get_dims();
      int_lrs   := sdo_input.get_lrs_dim();
      
      IF int_gtype = 1
      THEN
         RETURN point2geojson(
             p_input        => sdo_input
            ,p_pretty_print => p_pretty_print
            ,p_2d_flag      => str_2d_flag
            ,p_prune_number => p_prune_number
         );
         
      ELSIF int_gtype = 2
      THEN
         RETURN line2geojson(
             p_input        => sdo_input
            ,p_pretty_print => p_pretty_print
            ,p_2d_flag      => str_2d_flag
            ,p_prune_number => p_prune_number
         ); 
           
      ELSIF int_gtype = 3
      THEN
         RETURN polygon2geojson(
             p_input        => sdo_input
            ,p_pretty_print => p_pretty_print
            ,p_2d_flag      => str_2d_flag
            ,p_prune_number => p_prune_number
         );
         
      ELSIF int_gtype = 4
      THEN
         RETURN collection2geojson(
             p_input        => sdo_input
            ,p_pretty_print => p_pretty_print
            ,p_2d_flag      => str_2d_flag
            ,p_prune_number => p_prune_number
         );
     
      ELSIF int_gtype = 5
      THEN
         IF MDSYS.SDO_UTIL.GETNUMELEM(sdo_input) = 1
         THEN
            RETURN pointcluster2geojson(
                p_input        => sdo_input
               ,p_pretty_print => p_pretty_print
               ,p_2d_flag      => str_2d_flag
               ,p_prune_number => p_prune_number
            );
            
         ELSE
            RETURN multipoint2geojson(
                p_input        => sdo_input
               ,p_pretty_print => p_pretty_print
               ,p_2d_flag      => str_2d_flag
               ,p_prune_number => p_prune_number
            );
             
         END IF;
         
      ELSIF int_gtype = 6
      THEN
         RETURN multiline2geojson(
             p_input        => sdo_input
            ,p_pretty_print => p_pretty_print
            ,p_2d_flag      => str_2d_flag
            ,p_prune_number => p_prune_number
         );
         
      ELSIF int_gtype = 7
      THEN
         RETURN multipolygon2geojson(
             p_input        => sdo_input
            ,p_pretty_print => p_pretty_print
            ,p_2d_flag      => str_2d_flag
            ,p_prune_number => p_prune_number
         );
         
      ELSE
         RAISE_APPLICATION_ERROR(
             -20001
            ,'unknown gtype of ' || int_gtype
         );
      
      END IF;
       
   END sdo2geojson;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2bbox(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      sdo_input    MDSYS.SDO_GEOMETRY := p_input;
      sdo_mbr_geom MDSYS.SDO_GEOMETRY;
      
   BEGIN
      IF sdo_input IS NULL
      OR sdo_input.get_gtype() = 1
      THEN
         RETURN 'null';
         
      END IF;
      
      sdo_input := transform(
          p_input       => sdo_input
         ,p_output_srid => p_output_srid
      );
      
      sdo_mbr_geom := MDSYS.SDO_GEOM.SDO_MBR(
         geom => sdo_input
      );
         
      IF sdo_mbr_geom.get_gtype() = 3
      THEN
         RETURN '[' ||
            dz_json_util.prune_number(
                p_input => sdo_mbr_geom.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            ) || ',' ||
            dz_json_util.prune_number(
                p_input => sdo_mbr_geom.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ) || ',' ||
            dz_json_util.prune_number(
                p_input => sdo_mbr_geom.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            ) || ',' ||
            dz_json_util.prune_number(
                p_input => sdo_mbr_geom.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            ) ||
         ']';
         
      ELSE
         RETURN 'null';
            
      END IF;
         
   END sdo2bbox;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION srid2geojson_crs(
       p_input            IN  NUMBER
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      str_urn    VARCHAR2(4000 Char);
      clb_output CLOB := '';
      str_pad    VARCHAR2(1 Char);
      clb_inner  CLOB;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Determine the urn
      --------------------------------------------------------------------------
      IF p_input = 8265
      THEN
         str_urn := 'urn:ogc:def:crs:OGC::CRS83';
         
      ELSIF p_input = 8307
      THEN
         str_urn := 'urn:ogc:def:crs:OGC::CRS84';
      
      ELSE
         str_urn := 'urn:ogc:def:crs:EPSG::' || TO_CHAR(p_input);
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output := dz_json_util.pretty('{',NULL);
         clb_inner  := dz_json_util.pretty('{',NULL);
         str_pad    := '';
         
      ELSE
         clb_output := dz_json_util.pretty('{',-1);
         clb_inner  := dz_json_util.pretty('{',-1);
         str_pad    := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Build the crs inner object
      --------------------------------------------------------------------------
      clb_inner := clb_inner || dz_json_util.pretty(
          dz_json_main.value2json(
              'name'
             ,str_urn
             ,p_pretty_print + 2
          )
         ,p_pretty_print + 2
      ) || dz_json_util.pretty(
          str_pad || '}'
         ,p_pretty_print + 1,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Build the crs top object
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'name'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      ) || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'properties'
             ,clb_inner
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );

      --------------------------------------------------------------------------
      -- Step 50
      -- Add the left bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 60
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
   
   END srid2geojson_crs;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2geojson_feature(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_add_crs          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_add_bbox         IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_properties       IN  CLOB     DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_output   CLOB := '';
      str_add_crs  VARCHAR2(4000 Char) := UPPER(p_add_crs);
      str_add_bbox VARCHAR2(4000 Char) := UPPER(p_add_bbox);
      str_pad      VARCHAR2(1 Char);
      sdo_input    MDSYS.SDO_GEOMETRY := p_input;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_add_crs IS NULL
      THEN
         str_add_crs := 'TRUE';
         
      ELSIF str_add_crs NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      IF str_add_bbox IS NULL
      THEN
         str_add_bbox := 'TRUE';
         
      ELSIF str_add_bbox NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Transform if required
      --------------------------------------------------------------------------   
      IF p_output_srid IS NOT NULL
      AND p_output_srid != sdo_input.SDO_SRID
      THEN
         -- Try to avoid transforming over equal SRIDs
         IF  p_output_srid IN (4269,8265)
         AND sdo_input.SDO_SRID IN (4269,8265)
         THEN
            NULL;
            
         ELSIF  p_output_srid IN (4326,8307)
         AND sdo_input.SDO_SRID IN (4326,8307)
         THEN
            NULL;
            
         ELSIF  p_output_srid IN (3857,3785)
         AND sdo_input.SDO_SRID IN (3857,3785)
         THEN
            NULL;
            
         ELSE
            sdo_input := MDSYS.SDO_CS.TRANSFORM(sdo_input,p_output_srid);
            
         END IF;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output := dz_json_util.pretty('{',NULL);
         str_pad    := '';
         
      ELSE
         clb_output := dz_json_util.pretty('{',-1);
         str_pad    := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Build the object basics
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'Feature'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Add crs on demand
      --------------------------------------------------------------------------
      IF str_add_crs = 'TRUE'
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'crs'
                ,srid2geojson_crs(
                     p_input        => sdo_input.SDO_SRID
                    ,p_pretty_print => p_pretty_print + 1
                 )
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Add bbox on demand
      --------------------------------------------------------------------------
      IF str_add_bbox = 'TRUE'
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'bbox'
                ,sdo2bbox(
                     p_input        => sdo_input
                    ,p_output_srid  => p_output_srid
                    ,p_prune_number => p_prune_number
                 )
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 60
      -- Add geometry
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'geometry'
             ,sdo2geojson(
                  p_input        => sdo_input
                 ,p_pretty_print => p_pretty_print + 1
                 ,p_2d_flag      => p_2d_flag
                 ,p_output_srid  => NULL
                 ,p_prune_number => p_prune_number
              )
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Add Properties
      --------------------------------------------------------------------------
      IF p_properties IS NULL
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'properties'
                ,'null'
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
      
      ELSE
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'properties'
                ,p_properties
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
      
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 80
      -- Add the left bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 90
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
   
   END sdo2geojson_feature;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION fastname(
       p_name             IN  VARCHAR2
      ,p_pretty_print     IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2
   AS
      str_output VARCHAR2(4000 Char);
      
   BEGIN
      str_output := '"' || p_name || '":';
      
      IF p_pretty_print IS NOT NULL
      THEN
         str_output := str_output || ' ';
         
      END IF;
      
      RETURN str_output;
      
   END fastname; 
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION json_format(
       p_input            IN  VARCHAR2
      ,p_quote_strings    IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN VARCHAR2
   AS
      str_output VARCHAR2(4000 Char);
   
   BEGIN
   
      IF p_input IS NULL
      THEN
         RETURN 'null';
         
      ELSE
         str_output := REGEXP_REPLACE(
             REGEXP_REPLACE(p_input ,'\\','\\\')
            ,'/'
            ,'\/'
         );
         
         str_output := REGEXP_REPLACE(
             REGEXP_REPLACE(str_output,'"','\"')
            ,CHR(8)
            ,'\b'
         );
         
         str_output := REGEXP_REPLACE(
             REGEXP_REPLACE(str_output,CHR(12),'\f')
            ,CHR(10)
            ,'\n'
         );
         
         str_output := REGEXP_REPLACE(
             REGEXP_REPLACE(str_output,CHR(13),'\r')
            ,CHR(9)
            ,'\t'
         );
         
         str_output := REGEXP_REPLACE(
             REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                           REGEXP_REPLACE(
                              REGEXP_REPLACE(str_output,CHR(50099),'\u00F3')
                             ,CHR(50097)
                             ,'\u00D1'
                           )
                          ,CHR(50089)
                          ,'\u00E9'
                        )
                       ,CHR(50090)
                       ,'\u00EA'
                   )
                   ,CHR(50080)
                   ,'\u00E0'
               )
               ,CHR(50088)
               ,'\u00E8'
            )
            ,CHR(50057)
            ,'\u00C9'
         );
         
         IF p_quote_strings = 'FALSE'
         THEN 
            RETURN str_output;
            
         ELSE
            RETURN '"' || str_output || '"';
            
         END IF;
         
      END IF;
      
   END json_format;   
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION json_format(
       p_input            IN  NUMBER
      ,p_quote_strings    IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN VARCHAR2
   AS
      str_output VARCHAR2(4000 Char);
      
   BEGIN
   
      IF p_input IS NULL
      THEN
         RETURN 'null';
         
      ELSE
         str_output := TO_CHAR(p_input);
         
         IF SUBSTR(str_output,1,1) = '.'
         THEN
            RETURN '0' || str_output;
            
         ELSIF SUBSTR(str_output,1,2) = '-.'
         THEN
            RETURN '-0' || SUBSTR(str_output,2);
            
         ELSE
            RETURN str_output;
            
         END IF;
         
      END IF;
      
   END json_format;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION json_format(
       p_input            IN  DATE
      ,p_quote_strings    IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN VARCHAR2
   AS
   BEGIN
      IF p_input IS NULL
      THEN
         RETURN 'null';
         
      ELSE
         IF p_quote_strings = 'FALSE'
         THEN 
            RETURN TO_CHAR(TO_TIMESTAMP(p_input),'YYYY-MM-DD"T"HH24:MI:SS.FF2TZR');
            
         ELSE
            RETURN '"' || TO_CHAR(TO_TIMESTAMP(p_input),'YYYY-MM-DD"T"HH24:MI:SS.FF2TZR') || '"';
            
         END IF;
         
      END IF;
      
   END json_format;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION json_format(
       p_input            IN  CLOB
      ,p_quote_strings    IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      clb_output CLOB;
      
   BEGIN
   
      IF p_input IS NULL
      THEN
         RETURN TO_CLOB('null');
         
      ELSE
         clb_output := REGEXP_REPLACE(
             REGEXP_REPLACE(p_input ,'\\','\\\')
            ,'/'
            ,'\/'
         );
         
         clb_output := REGEXP_REPLACE(
             REGEXP_REPLACE(clb_output,'"','\"')
            ,CHR(8)
            ,'\b'
         );
         
         clb_output := REGEXP_REPLACE(
             REGEXP_REPLACE(clb_output,CHR(12),'\f')
            ,CHR(10)
            ,'\n'
         );
         
         clb_output := REGEXP_REPLACE(
             REGEXP_REPLACE(clb_output,CHR(13),'\r')
            ,CHR(9)
            ,'\t'
         );
         
         clb_output := REGEXP_REPLACE(
             REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                           REGEXP_REPLACE(
                              REGEXP_REPLACE(clb_output,CHR(50099),'\u00F3')
                             ,CHR(50097)
                             ,'\u00D1'
                           )
                          ,CHR(50089)
                          ,'\u00E9'
                        )
                       ,CHR(50090)
                       ,'\u00EA'
                   )
                   ,CHR(50080)
                   ,'\u00E0'
               )
               ,CHR(50088)
               ,'\u00E8'
            )
            ,CHR(50057)
            ,'\u00C9'
         );
         
         IF p_quote_strings = 'FALSE'
         THEN 
            RETURN clb_output;
            
         ELSE
            RETURN TO_CLOB('"') || clb_output || TO_CLOB('"');
            
         END IF;
         
      END IF;
   
   END json_format;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  VARCHAR2
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
      RETURN TO_CLOB(
         fastname(
             p_name
            ,p_pretty_print
         ) || json_format(p_input)
      );

   END value2json;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  NUMBER
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
      RETURN TO_CLOB(
         fastname(
             p_name
            ,p_pretty_print
         ) || json_format(p_input)
      );
      
   END value2json;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  DATE
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
      RETURN TO_CLOB(
         fastname(
             p_name
            ,p_pretty_print
         ) || json_format(p_input)
      );
      
   END value2json;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  CLOB
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
      RETURN TO_CLOB(
         fastname(
             p_name
            ,p_pretty_print
         ) || json_format(p_input)
      );

   END value2json;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  MDSYS.SDO_STRING2_ARRAY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_output CLOB;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Build the json value name
      --------------------------------------------------------------------------
      clb_output := TO_CLOB(
         fastname(p_name,p_pretty_print)
      );
     
      --------------------------------------------------------------------------
      -- Step 20
      -- Exit if value is NULL
      --------------------------------------------------------------------------
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         RETURN clb_output || TO_CLOB('null');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Start bracket the array with brace
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             '['
            ,NULL
         );
                    
      ELSE
         clb_output := clb_output || dz_json_util.pretty(
             '['
            ,-1
         );
                    
      END IF;
         
      --------------------------------------------------------------------------
      -- Step 40
      -- Spin out the values
      --------------------------------------------------------------------------
      FOR i IN 1 .. p_input.COUNT
      LOOP
         IF i < p_input.COUNT
         THEN
            clb_output := clb_output || dz_json_util.pretty(
                json_format(p_input(i)) || ','
               ,p_pretty_print + 1
            );
                       
         ELSE
            clb_output := clb_output || dz_json_util.pretty(
                json_format(p_input(i))
               ,p_pretty_print + 1
            );
                       
         END IF;
            
      END LOOP;  
         
      --------------------------------------------------------------------------
      -- Step 50
      -- End bracket the array with brace
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          ']'
         ,p_pretty_print
         ,NULL
         ,NULL
      );
 
      --------------------------------------------------------------------------
      -- Step 60
      -- Return the results
      --------------------------------------------------------------------------
      RETURN clb_output;
      
   END value2json;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION value2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  MDSYS.SDO_NUMBER_ARRAY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_output CLOB;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Build the json value name
      --------------------------------------------------------------------------
      clb_output := fastname(
          p_name
         ,p_pretty_print
      );
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Exit if value is NULL
      --------------------------------------------------------------------------
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         RETURN clb_output || TO_CLOB('null');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Start bracket the array with brace
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             '['
            ,NULL
         );
                    
      ELSE
         clb_output := clb_output || dz_json_util.pretty(
             '['
            ,-1
         );
                    
      END IF;
   
      --------------------------------------------------------------------------
      -- Step 40
      -- Spin out the values
      --------------------------------------------------------------------------
      FOR i IN 1 .. p_input.COUNT
      LOOP
         IF i < p_input.COUNT
         THEN
            clb_output := clb_output || dz_json_util.pretty(
                json_format(p_input(i)) || ','
               ,p_pretty_print + 1
            );
                        
         ELSE
            clb_output := clb_output || dz_json_util.pretty(
                json_format(p_input(i))
               ,p_pretty_print + 1
            );
                       
         END IF;
            
      END LOOP;  
         
      --------------------------------------------------------------------------
      -- Step 50
      -- End bracket the array with brace
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          ']'
         ,p_pretty_print
         ,NULL
         ,NULL
      );
 
      --------------------------------------------------------------------------
      -- Step 60
      -- Return the results
      --------------------------------------------------------------------------
      RETURN clb_output;
   
   END value2json;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION formatted2json(
       p_name             IN  VARCHAR2
      ,p_input            IN  CLOB
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
      RETURN TO_CLOB(
         fastname(
             p_name          => p_name
            ,p_pretty_print  => p_pretty_print
         ) || p_input
      );
      
   END formatted2json;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION empty_scalar2json(
       p_name             IN  VARCHAR2
      ,p_comma_flag       IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN VARCHAR2
   AS
      str_output     VARCHAR2(4000 Char);
      str_comma_flag VARCHAR2(5 Char) := UPPER(p_comma_flag);
      
   BEGIN
      
      IF str_comma_flag IS NULL
      THEN
         str_comma_flag := 'FALSE';
         
      ELSIF str_comma_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      str_output := fastname(p_name,p_pretty_print) || 'null';
      
      IF p_comma_flag = 'TRUE'
      THEN
         str_output := str_output || ',';
         
      END IF;
      
      RETURN dz_json_util.pretty(
          str_output
         ,p_pretty_print
      );
      
   END empty_scalar2json;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION empty_array2json(
       p_name             IN  VARCHAR2
      ,p_comma_flag       IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN VARCHAR2
   AS
      str_output     VARCHAR2(4000 Char);
      str_comma_flag VARCHAR2(5 Char) := UPPER(p_comma_flag);
      
   BEGIN
      
      IF str_comma_flag IS NULL
      THEN
         str_comma_flag := 'FALSE';
         
      ELSIF str_comma_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'boolean error'
         );
         
      END IF;
      
      str_output := fastname(p_name,p_pretty_print) || '[]';
      
      IF p_comma_flag = 'TRUE'
      THEN
         str_output := str_output || ',';
         
      END IF;
      
      RETURN dz_json_util.pretty(
          str_output
         ,p_pretty_print
      );
      
   END empty_array2json;
   
END dz_json_main;
/


--*************************--
PROMPT DZ_JSON_TEST.pks;

CREATE OR REPLACE PACKAGE dz_json_test
AUTHID DEFINER
AS

   C_TFS_CHANGESET CONSTANT NUMBER := 8323;
   C_JENKINS_JOBNM CONSTANT VARCHAR2(255 Char) := 'NULL';
   C_JENKINS_BUILD CONSTANT NUMBER := 4;
   C_JENKINS_BLDID CONSTANT VARCHAR2(255 Char) := 'NULL';
   
   C_PREREQUISITES CONSTANT MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY(
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER;
   
END dz_json_test;
/

GRANT EXECUTE ON dz_json_test TO public;


--*************************--
PROMPT DZ_JSON_TEST.pkb;

CREATE OR REPLACE PACKAGE BODY dz_json_test
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER
   AS
      num_check NUMBER;
      
   BEGIN
      
      FOR i IN 1 .. C_PREREQUISITES.COUNT
      LOOP
         SELECT 
         COUNT(*)
         INTO num_check
         FROM 
         user_objects a
         WHERE 
             a.object_name = C_PREREQUISITES(i) || '_TEST'
         AND a.object_type = 'PACKAGE';
         
         IF num_check <> 1
         THEN
            RETURN 1;
         
         END IF;
      
      END LOOP;
      
      RETURN 0;
   
   END prerequisites;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2
   AS
   BEGIN
      RETURN '{"TFS":' || C_TFS_CHANGESET || ','
      || '"JOBN":"' || C_JENKINS_JOBNM || '",'   
      || '"BUILD":' || C_JENKINS_BUILD || ','
      || '"BUILDID":"' || C_JENKINS_BLDID || '"}';
      
   END version;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER
   AS
      num_test     NUMBER;
      num_results  NUMBER := 0;
      clb_results  CLOB;

   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check 2D Point 
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2001
             ,8265
             ,MDSYS.SDO_POINT_TYPE(-87.845556,42.582222,NULL)
             ,NULL
             ,NULL
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"Point","coordinates":[-87.845556,42.582222]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Point: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Check 2D Point Cluster
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2005
             ,8265
             ,NULL
             ,MDSYS.SDO_ELEM_INFO_ARRAY(
                  1
                 ,1
                 ,3
              )
             ,MDSYS.SDO_ORDINATE_ARRAY(
                  -72.45454
                 ,42.23232
                 ,-71.78787
                 ,42.989898
                 ,-71.334455
                 ,42.515151
              )
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"MultiPoint","coordinates":[[-72.45454,42.23232],[-71.78787,42.989898],[-71.334455,42.515151]]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Point Cluster: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Check 2D Linestring 
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2002
             ,8265
             ,NULL
             ,MDSYS.SDO_ELEM_INFO_ARRAY(
                  1
                 ,2
                 ,1
              )
             ,MDSYS.SDO_ORDINATE_ARRAY(
                  -71.160281
                 ,42.258729
                 ,-71.260837
                 ,42.259113
                 ,-71.361144
                 ,42.25932
              )
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"LineString","coordinates":[[-71.160281,42.258729],[-71.260837,42.259113],[-71.361144,42.25932]]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Linestring: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Check 2D Polygon 
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2003
             ,8265
             ,NULL
             ,MDSYS.SDO_ELEM_INFO_ARRAY(
                  1
                 ,1003
                 ,1
              )
             ,MDSYS.SDO_ORDINATE_ARRAY(
                  -77.2903337908711
                 ,41.9901156015547
                 ,-77.2898433240096
                 ,41.9903066678044
                 ,-77.2906707236743
                 ,41.9905902014476
                 ,-77.2903337908711
                 ,41.9901156015547
              )
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"Polygon","coordinates":[[[-77.2903337908711,41.9901156015547],[-77.2898433240096,41.9903066678044],[-77.2906707236743,41.9905902014476],[-77.2903337908711,41.9901156015547]]]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Polygon: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Check 2D Rectangle 
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2003
             ,8265
             ,NULL
             ,MDSYS.SDO_ELEM_INFO_ARRAY(
                  1
                 ,1003
                 ,3
              )
             ,MDSYS.SDO_ORDINATE_ARRAY(
                  -77.2903337908711
                 ,41.9901156015547
                 ,-76.2898433240096
                 ,42.9903066678044
              )
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"Polygon","coordinates":[[[-77.2903337908711,41.9901156015547],[-76.2898433240096,41.9901156015547],[-76.2898433240096,42.9903066678044],[-77.2903337908711,42.9903066678044],[-77.2903337908711,41.9901156015547]]]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Rectangle: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 60
      -- Check 2D Polygon with hole
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2003
             ,8265
             ,NULL
             ,MDSYS.SDO_ELEM_INFO_ARRAY(
                  1
                 ,1003
                 ,1
                 ,33
                 ,2003
                 ,1
              )
             ,MDSYS.SDO_ORDINATE_ARRAY(
                  -69.2352824697095
                 ,46.6621271945153
                 ,-69.2350178693785
                 ,46.6626301943289
                 ,-69.2349856026028
                 ,46.6630875274683
                 ,-69.2353518029427
                 ,46.663589993984
                 ,-69.2354856697272
                 ,46.6641613278839
                 ,-69.2357848696753
                 ,46.6643667941931
                 ,-69.2362164696137
                 ,46.664366327445
                 ,-69.236847003186
                 ,46.6641599941893
                 ,-69.2374438031883
                 ,46.6637707271383
                 ,-69.2376754694467
                 ,46.6634275944089
                 ,-69.237541269913
                 ,46.6627877276724
                 ,-69.2372414692177
                 ,46.6623079942195
                 ,-69.2368756699755
                 ,46.6620111945619
                 ,-69.2363110027499
                 ,46.6618517942258
                 ,-69.2360122695499
                 ,46.6618521944242
                 ,-69.2352824697095
                 ,46.6621271945153
                 ,-69.2364458030307
                 ,46.6628803272662
                 ,-69.2367118692567
                 ,46.6631085940872
                 ,-69.2365794692664
                 ,46.6632915944325
                 ,-69.2361148696049
                 ,46.6633835276286
                 ,-69.2359154692228
                 ,46.6632923273799
                 ,-69.2359150699239
                 ,46.6631093944839
                 ,-69.2364458030307
                 ,46.6628803272662
              )
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"Polygon","coordinates":[[[-69.2352824697095,46.6621271945153],[-69.2350178693785,46.6626301943289],[-69.2349856026028,46.6630875274683],[-69.2353518029427,46.663589993984],[-69.2354856697272,46.6641613278839],[-69.2357848696753,46.6643667941931],[-69.2362164696137,46.664366327445],[-69.236847003186,46.6641599941893],[-69.2374438031883,46.6637707271383],[-69.2376754694467,46.6634275944089],[-69.237541269913,46.6627877276724],[-69.2372414692177,46.6623079942195],[-69.2368756699755,46.6620111945619],[-69.2363110027499,46.6618517942258],[-69.2360122695499,46.6618521944242],[-69.2352824697095,46.6621271945153]],[[-69.2364458030307,46.6628803272662],[-69.2367118692567,46.6631085940872],[-69.2365794692664,46.6632915944325],[-69.2361148696049,46.6633835276286],[-69.2359154692228,46.6632923273799],[-69.2359150699239,46.6631093944839],[-69.2364458030307,46.6628803272662]]]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Polygon with hole: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Check 2D Multipoint
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2005
             ,8265
             ,NULL
             ,MDSYS.SDO_ELEM_INFO_ARRAY(
                  1
                 ,1
                 ,1
                 ,3
                 ,1
                 ,1
                 ,5
                 ,1
                 ,1
              )
             ,MDSYS.SDO_ORDINATE_ARRAY(
                  -72.45454
                 ,42.23232
                 ,-71.78787
                 ,42.989898
                 ,-71.334455
                 ,42.515151
              )
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"MultiPoint","coordinates":[[-72.45454,42.23232],[-71.78787,42.989898],[-71.334455,42.515151]]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D MultiPoint: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 80
      -- Check 2D MultiLinestring
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2006
             ,8265
             ,NULL
             ,MDSYS.SDO_ELEM_INFO_ARRAY(
                  1
                 ,2
                 ,1
                 ,5
                 ,2
                 ,1
              )
             ,MDSYS.SDO_ORDINATE_ARRAY(
                  -78.3466269890437
                 ,38.83615220656
                 ,-78.3475923887771
                 ,38.8354434067887
                 ,-71.1501673996052
                 ,43.0729051996162
                 ,-71.150759800124
                 ,43.0725619994377
                 ,-71.1507907997549
                 ,43.0723791330914
              )
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"MultiLineString","coordinates":[[[-78.3466269890437,38.83615220656],[-78.3475923887771,38.8354434067887]],[[-71.1501673996052,43.0729051996162],[-71.150759800124,43.0725619994377],[-71.1507907997549,43.0723791330914]]]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D MultiLineString: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 90
      -- Check 2D MultiPolygon
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2007
             ,8265
             ,NULL
             ,MDSYS.SDO_ELEM_INFO_ARRAY(
                  1
                 ,1003
                 ,1
                 ,71
                 ,1003
                 ,1
              )
             ,MDSYS.SDO_ORDINATE_ARRAY(
                  -87.0000061752442
                 ,38.7082849396991
                 ,-87.0000061752442
                 ,38.7095630067283
                 ,-87.0007041085071
                 ,38.7095636731259
                 ,-87.0012883090076
                 ,38.709724606806
                 ,-87.0015215751599
                 ,38.7099536731244
                 ,-87.0022805750878
                 ,38.7102750062874
                 ,-87.0024263749766
                 ,38.7104582728319
                 ,-87.0023967755901
                 ,38.7106642067886
                 ,-87.0026301757414
                 ,38.7108246728213
                 ,-87.0032729086172
                 ,38.7108254066681
                 ,-87.0036231756684
                 ,38.7110088728621
                 ,-87.0036221090724
                 ,38.7116726732561
                 ,-87.0044399084744
                 ,38.7118566061983
                 ,-87.0047893751289
                 ,38.7124064067312
                 ,-87.005256908379
                 ,38.7124068069295
                 ,-87.0062807757366
                 ,38.7115608731367
                 ,-87.006397708287
                 ,38.7115610736855
                 ,-87.0065151084848
                 ,38.7112178069571
                 ,-87.0063401085085
                 ,38.7110344729634
                 ,-87.0060783752162
                 ,38.7102788733722
                 ,-87.0054359750895
                 ,38.7101408733035
                 ,-87.004706375798
                 ,38.709613673633
                 ,-87.0035383749953
                 ,38.7093378065954
                 ,-87.0030133085168
                 ,38.7089022730224
                 ,-87.0025461089152
                 ,38.708695806667
                 ,-87.0024879758388
                 ,38.7085354728347
                 ,-87.001932908876
                 ,38.7085120733744
                 ,-87.0015533751875
                 ,38.7083972065667
                 ,-87.0008825088201
                 ,38.7077556068367
                 ,-87.0005905753941
                 ,38.7076638067402
                 ,-87.0004733757451
                 ,38.7078696066979
                 ,-87.0006771090607
                 ,38.7083276736841
                 ,-87.0002681090853
                 ,38.708327206936
                 ,-87.0000061752442
                 ,38.7082354068394
                 ,-87.0000061752442
                 ,38.7082849396991
                 ,-87.0000061752442
                 ,38.7095630067283
                 ,-86.9995977751166
                 ,38.7080756063051
                 ,-86.9994811087655
                 ,38.7080986064664
                 ,-86.9994523754261
                 ,38.7084420062944
                 ,-86.9996279752502
                 ,38.7086478062521
                 ,-86.9997459752959
                 ,38.7093114735466
                 ,-87.0000061752442
                 ,38.7095630067283
              )
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"MultiPolygon","coordinates":[[[[-87.0000061752442,38.7082849396991],[-87.0000061752442,38.7095630067283],[-87.0007041085071,38.7095636731259],[-87.0012883090076,38.709724606806],[-87.0015215751599,38.7099536731244],[-87.0022805750878,38.7102750062874],[-87.0024263749766,38.7104582728319],[-87.0023967755901,38.7106642067886],[-87.0026301757414,38.7108246728213],[-87.0032729086172,38.7108254066681],[-87.0036231756684,38.7110088728621],[-87.0036221090724,38.7116726732561],[-87.0044399084744,38.7118566061983],[-87.0047893751289,38.7124064067312],[-87.005256908379,38.7124068069295],[-87.0062807757366,38.7115608731367],[-87.006397708287,38.7115610736855],[-87.0065151084848,38.7112178069571],[-87.0063401085085,38.7110344729634],[-87.0060783752162,38.7102788733722],[-87.0054359750895,38.7101408733035],[-87.004706375798,38.709613673633],[-87.0035383749953,38.7093378065954],[-87.0030133085168,38.7089022730224],[-87.0025461089152,38.708695806667],[-87.0024879758388,38.7085354728347],[-87.001932908876,38.7085120733744],[-87.0015533751875,38.7083972065667],[-87.0008825088201,38.7077556068367],[-87.0005905753941,38.7076638067402],[-87.0004733757451,38.7078696066979],[-87.0006771090607,38.7083276736841],[-87.0002681090853,38.708327206936],[-87.0000061752442,38.7082354068394],[-87.0000061752442,38.7082849396991]]],[[[-87.0000061752442,38.7095630067283],[-86.9995977751166,38.7080756063051],[-86.9994811087655,38.7080986064664],[-86.9994523754261,38.7084420062944],[-86.9996279752502,38.7086478062521],[-86.9997459752959,38.7093114735466],[-87.0000061752442,38.7095630067283]]]]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D MultiPolygon: ' || num_test);
      
      --------------------------------------------------------------------------
      -- Step 100
      -- Check 2D Collection
      --------------------------------------------------------------------------
      clb_results := dz_json_main.sdo2geojson(
          p_input => MDSYS.SDO_GEOMETRY(
              2004
             ,8265
             ,NULL
             ,MDSYS.SDO_ELEM_INFO_ARRAY(
                  1
                 ,1
                 ,1
                 ,3
                 ,2
                 ,1
                 ,7
                 ,1003
                 ,1
                 ,17
                 ,2003
                 ,1
              )
             ,MDSYS.SDO_ORDINATE_ARRAY(
                  4
                 ,6
                 ,4
                 ,6
                 ,7
                 ,10
                 ,3
                 ,10
                 ,45
                 ,45
                 ,15
                 ,40
                 ,10
                 ,20
                 ,35
                 ,10
                 ,20
                 ,30
                 ,35
                 ,35
                 ,30
                 ,20
                 ,20
                 ,30
              )
          )
         ,p_pretty_print => NULL
      );
      
      IF clb_results = '{"type":"GeometryCollection","geometries":[{"type":"Point","coordinates":[4,6]},{"type":"LineString","coordinates":[[4,6],[7,10]]},{"type":"Polygon","coordinates":[[[3,10],[45,45],[15,40],[10,20],[35,10]],[[20,30],[35,35],[30,20],[20,30]]]}]}'
      THEN
         num_test := 0;
      
      ELSE
         num_test := 1;
            
      END IF;
      
      num_results := num_results + num_test;
      dbms_output.put_line('Check 2D Collection: ' || num_test);
      
      RETURN num_results;
      
   END inmemory_test;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END scratch_test;

END dz_json_test;
/


--*************************--
PROMPT DZ_JSON_PROPERTIES.tps;

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


--*************************--
PROMPT DZ_JSON_PROPERTIES.tpb;

CREATE OR REPLACE TYPE BODY dz_json_properties 
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_properties
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_json_properties;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_properties(
       p_name               IN  VARCHAR2
      ,p_properties_string  IN  VARCHAR2
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_properties_string IS NULL
      THEN
         self.properties_null := 1;
         
      ELSE
         self.properties_string := p_properties_string;
         
      END IF;
      
      self.properties_name := p_name;
      
      RETURN;
      
   END dz_json_properties;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_properties(
       p_name               IN  VARCHAR2
      ,p_properties_number  IN  NUMBER
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_properties_number IS NULL
      THEN
         self.properties_null := 1;
         
      ELSE
         self.properties_number := p_properties_number;
         
      END IF;
      
      self.properties_name := p_name;
      
      RETURN;
      
   END dz_json_properties;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_properties(
       p_name               IN  VARCHAR2
      ,p_properties_date    IN  DATE
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_properties_date IS NULL
      THEN
         self.properties_null := 1;
         
      ELSE
         self.properties_date := p_properties_date;
         
      END IF;
      
      self.properties_name := p_name;
      
      RETURN;
      
   END dz_json_properties;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_properties(
       p_name               IN  VARCHAR2
      ,p_properties_complex IN  CLOB
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_properties_complex IS NULL
      THEN
         self.properties_null := 1;
         
      ELSE
         self.properties_complex := p_properties_complex;
         
      END IF;
      
      self.properties_name := p_name;
      
      RETURN;
      
   END dz_json_properties;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION isNULL
   RETURN VARCHAR2
   AS
   BEGIN
      IF self.properties_null = 1
      THEN
         RETURN 'TRUE';
         
      END IF;
      
      IF  self.properties_string IS NULL
      AND self.properties_number IS NULL
      AND self.properties_date IS NULL
      AND self.properties_complex IS NULL
      THEN
         RETURN 'TRUE';
         
      END IF;
      
      RETURN 'FALSE';
      
   END isNULL;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION toJSONpair(
       p_leader_char      IN  VARCHAR2 DEFAULT NULL
   ) RETURN CLOB
   AS
      num_pretty_print NUMBER;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Pseudo pretty pring
      --------------------------------------------------------------------------
      IF LENGTH(p_leader_char) > 0
      THEN
         num_pretty_print := 0;
         
      ELSE
         num_pretty_print := NULL;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Account for null
      --------------------------------------------------------------------------
      IF self.isNULL() = 'TRUE'
      THEN
         RETURN p_leader_char || dz_json_main.fastname(
             p_name         => self.properties_name
            ,p_pretty_print => num_pretty_print
         ) || 'null';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- String output
      --------------------------------------------------------------------------
      IF self.properties_string IS NOT NULL
      THEN
         RETURN p_leader_char || dz_json_main.fastname(
             p_name         => self.properties_name
            ,p_pretty_print => num_pretty_print
         ) || dz_json_main.json_format(
             p_input        => self.properties_string
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Number output
      --------------------------------------------------------------------------
      IF self.properties_number IS NOT NULL
      THEN
         RETURN p_leader_char || dz_json_main.fastname(
             p_name         => self.properties_name
            ,p_pretty_print => num_pretty_print
         ) || dz_json_main.json_format(
             p_input        => self.properties_number
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Date output
      --------------------------------------------------------------------------
      IF self.properties_date IS NOT NULL
      THEN
         RETURN p_leader_char || dz_json_main.fastname(
             p_name         => self.properties_name
            ,p_pretty_print => num_pretty_print
         ) || dz_json_main.json_format(
             p_input        => self.properties_date
         );
         
      END IF;
   
      --------------------------------------------------------------------------
      -- Step 60
      -- Complex output
      --------------------------------------------------------------------------
      IF self.properties_complex IS NOT NULL
      THEN
         RETURN p_leader_char || dz_json_main.fastname(
             p_name         => self.properties_name
            ,p_pretty_print => num_pretty_print
         ) || self.properties_complex;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Cough it out
      --------------------------------------------------------------------------
      RETURN p_leader_char || dz_json_main.fastname(
          p_name         => self.properties_name
         ,p_pretty_print => num_pretty_print
      ) || 'null';
           
   END toJSONpair;
   
END;
/


--*************************--
PROMPT DZ_JSON_PROPERTIES_VRY.tps;

CREATE OR REPLACE TYPE dz_json_properties_vry FORCE
AS 
VARRAY(1048576) OF dz_json_properties;
/

GRANT EXECUTE ON dz_json_properties_vry TO PUBLIC;


--*************************--
PROMPT DZ_JSON_FEATURE.tps;

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


--*************************--
PROMPT DZ_JSON_FEATURE.tpb;

CREATE OR REPLACE TYPE BODY dz_json_feature 
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_feature
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_json_feature;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_feature(
       p_geometry     IN  MDSYS.SDO_GEOMETRY
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.geometry   := p_geometry;
      RETURN;
      
   END dz_json_feature;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_feature(
       p_geometry     IN  MDSYS.SDO_GEOMETRY
      ,p_properties   IN  dz_json_properties_vry
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.geometry   := p_geometry;
      self.properties := p_properties;
      RETURN;
      
   END dz_json_feature;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION properties_count
   RETURN NUMBER
   AS
   BEGIN
     IF self.properties IS NOT NULL
     THEN
        RETURN self.properties.COUNT;
        
     ELSE
        RETURN NULL;
        
     END IF;
   
   END properties_count;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION transform(
       p_output_srid      IN  NUMBER 
   ) RETURN MDSYS.SDO_GEOMETRY
   AS
      sdo_output MDSYS.SDO_GEOMETRY;
      
   BEGIN
      IF self.geometry IS NULL
      THEN
         RETURN NULL;
         
      END IF;
      
      IF p_output_srid IS NULL
      THEN
         RETURN self.geometry;
         
      END IF;
   
      IF p_output_srid <> self.geometry.SDO_SRID
      THEN
         -- Try to avoid transforming over equal SRIDs
         IF  p_output_srid IN (4269,8265)
         AND self.geometry.SDO_SRID IN (4269,8265)
         THEN
            NULL;
         
         ELSIF  p_output_srid IN (4326,8307)
         AND self.geometry.SDO_SRID IN (4326,8307)
         THEN
            NULL;
            
         ELSIF  p_output_srid IN (3857,3785)
         AND self.geometry.SDO_SRID IN (3857,3785)
         THEN
            NULL;
            
         ELSE
            sdo_output := MDSYS.SDO_CS.TRANSFORM(self.geometry,p_output_srid);
            RETURN sdo_output;
            
         END IF;
         
      END IF;
      
      RETURN self.geometry;
      
   END transform;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION toJSON(
       p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_add_crs          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_add_bbox         IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      clb_output     CLOB;
      str_2d_flag    VARCHAR2(4000 Char) := UPPER(p_2d_flag);
      str_add_crs    VARCHAR2(4000 Char) := UPPER(p_add_crs);
      str_add_bbox   VARCHAR2(4000 Char) := UPPER(p_add_bbox);
      str_pad        VARCHAR2(1 Char);
      clb_properties CLOB;
      boo_first      BOOLEAN;
      sdo_input      MDSYS.SDO_GEOMETRY;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'TRUE';
         
      ELSIF str_2d_flag NOT IN ('FALSE','TRUE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      IF str_add_crs IS NULL
      THEN
         str_add_crs := 'TRUE';
         
      ELSIF str_add_crs NOT IN ('FALSE','TRUE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      IF str_add_bbox IS NULL
      THEN
         str_add_bbox := 'TRUE';
         
      ELSIF str_add_bbox NOT IN ('FALSE','TRUE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      sdo_input := self.geometry;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Transform if required
      --------------------------------------------------------------------------   
      IF p_output_srid IS NOT NULL
      AND p_output_srid != sdo_input.SDO_SRID
      THEN
         -- Try to avoid transforming over equal SRIDs
         IF  p_output_srid IN (4269,8265)
         AND sdo_input.SDO_SRID IN (4269,8265)
         THEN
            NULL;
            
         ELSE
            sdo_input := MDSYS.SDO_CS.TRANSFORM(sdo_input,p_output_srid);
            
         END IF;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output     := dz_json_util.pretty('{',NULL);
         clb_properties := dz_json_util.pretty('{',NULL);
         str_pad        := '';
         
      ELSE
         clb_output     := dz_json_util.pretty('{',-1);
         clb_properties := dz_json_util.pretty('{',-1);
         str_pad        := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Build the object basics
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'Feature'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add crs on demand
      --------------------------------------------------------------------------
      IF str_add_crs = 'TRUE'
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'crs'
                ,dz_json_main.srid2geojson_crs(
                     p_input        => sdo_input.SDO_SRID
                    ,p_pretty_print => p_pretty_print + 1
                 )
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Add crs on demand
      --------------------------------------------------------------------------
      IF str_add_bbox = 'TRUE'
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'bbox'
                ,dz_json_main.sdo2bbox(
                     p_input        => sdo_input
                    ,p_output_srid  => p_output_srid
                    ,p_prune_number => p_prune_number
                 )
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 60
      -- Add geometry
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'geometry'
             ,dz_json_main.sdo2geojson(
                  p_input        => sdo_input
                 ,p_pretty_print => p_pretty_print + 1
                 ,p_2d_flag      => str_2d_flag
                 ,p_output_srid  => p_output_srid
                 ,p_prune_number => p_prune_number
              )
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Add Properties
      --------------------------------------------------------------------------
      IF self.properties IS NULL
      OR self.properties.COUNT = 0
      THEN
         clb_properties := 'null';
      
      ELSE
         boo_first := TRUE;
         FOR i IN 1 .. self.properties.COUNT
         LOOP
            IF boo_first
            THEN
               clb_properties := clb_properties || dz_json_util.pretty(
                   self.properties(i).toJSONpair(
                      p_leader_char => str_pad
                   )
                  ,p_pretty_print + 2
               );
               boo_first := FALSE;
               
            ELSE
               clb_properties := clb_properties || dz_json_util.pretty(
                   self.properties(i).toJSONpair(
                      p_leader_char => ','
                   )
                  ,p_pretty_print + 2
               );
               
            END IF;
         
         END LOOP;
         
         clb_properties := clb_properties || dz_json_util.pretty(
             '}'
            ,p_pretty_print + 1,NULL,NULL
         );
      
      END IF;
      
      clb_output := clb_output || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'properties'
             ,clb_properties
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 80
      -- Add the left bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 90
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
           
   END toJSON;
   
END;
/


--*************************--
PROMPT DZ_JSON_FEATURE_VRY.tps;

CREATE OR REPLACE TYPE dz_json_feature_vry FORCE
AS 
VARRAY(1048576) OF dz_json_feature;
/

GRANT EXECUTE ON dz_json_feature_vry TO PUBLIC;


--*************************--
PROMPT DZ_JSON_FEATURE_COLLECTION.tps;

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


--*************************--
PROMPT DZ_JSON_FEATURE_COLLECTION.tpb;

CREATE OR REPLACE TYPE BODY dz_json_feature_collection 
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_feature_collection
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_json_feature_collection;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_feature_collection(
       p_features   IN  dz_json_feature_vry
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.features := p_features;
      RETURN;
      
   END dz_json_feature_collection;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION feature_count
   RETURN NUMBER
   AS
   BEGIN
     IF self.features IS NOT NULL
     THEN
        RETURN self.features.COUNT;
        
     ELSE
        RETURN NULL;
        
     END IF;
   
   END feature_count;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION bbox(
       p_output_srid  IN  NUMBER DEFAULT NULL
      ,p_prune_number IN  NUMBER DEFAULT NULL
   ) RETURN VARCHAR2
   AS
      sdo_aggr_geom MDSYS.SDO_GEOMETRY;
      sdo_temp      MDSYS.SDO_GEOMETRY;
      
   BEGIN
      IF self.features IS NULL
      OR self.features.COUNT = 0
      THEN
         RETURN 'null';
         
      ELSE
         FOR i IN 1 .. self.features.COUNT
         LOOP
            IF  sdo_aggr_geom IS NULL
            THEN
               sdo_aggr_geom := MDSYS.SDO_GEOM.SDO_MBR(
                  self.features(i).transform(
                     p_output_srid => p_output_srid
                  )
               );
               
            ELSE
               sdo_temp := dz_json_util.downsize_2d(
                  self.features(i).transform(
                      p_output_srid => p_output_srid
                  )
               );
               
               sdo_aggr_geom := MDSYS.SDO_GEOM.SDO_MBR(
                  MDSYS.SDO_UTIL.APPEND(
                      sdo_aggr_geom
                     ,sdo_temp
                  )
               );
            
            END IF; 
         
         END LOOP;
         
         RETURN dz_json_main.sdo2bbox(
             p_input => sdo_aggr_geom
            ,p_output_srid  => p_output_srid
            ,p_prune_number => p_prune_number
         );
      
      END IF;
   
   END bbox;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION toJSON(
       p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_output_srid      IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_add_crs          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_add_bbox         IN  VARCHAR2 DEFAULT 'TRUE'
   ) RETURN CLOB
   AS
      clb_output   CLOB;
      str_2d_flag  VARCHAR2(4000 Char) := UPPER(p_2d_flag);
      str_add_crs  VARCHAR2(4000 Char) := UPPER(p_add_crs);
      str_add_bbox VARCHAR2(4000 Char) := UPPER(p_add_bbox);
      str_pad      VARCHAR2(1 Char);
      clb_features CLOB;
      boo_first    BOOLEAN;
      clb_crs      CLOB;
      sdo_temp     MDSYS.SDO_GEOMETRY;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'TRUE';
         
      ELSIF str_2d_flag NOT IN ('FALSE','TRUE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      IF str_add_crs IS NULL
      THEN
         str_add_crs := 'TRUE';
         
      ELSIF str_add_crs NOT IN ('FALSE','TRUE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      IF str_add_bbox IS NULL
      THEN
         str_add_bbox := 'TRUE';
         
      ELSIF str_add_bbox NOT IN ('FALSE','TRUE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output   := dz_json_util.pretty('{',NULL);
         clb_features := dz_json_util.pretty('[',NULL);
         str_pad      := '';
         
      ELSE
         clb_output   := dz_json_util.pretty('{',-1);
         clb_features := dz_json_util.pretty('[',-1);
         str_pad      := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Build the object basics
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_pad || dz_json_main.value2json(
              'type'
             ,'FeatureCollection'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add crs on demand
      --------------------------------------------------------------------------
      IF str_add_crs = 'TRUE'
      THEN
         IF self.features IS NULL
         OR self.features.COUNT = 0
         OR self.features(1).geometry IS NULL
         THEN
            clb_crs := 'null';
            
         ELSE
            sdo_temp := self.features(1).transform(
               p_output_srid => p_output_srid
            );
         
            clb_crs := dz_json_main.srid2geojson_crs(
                p_input        => sdo_temp.SDO_SRID
               ,p_pretty_print => p_pretty_print + 1
            );
         
         END IF;
         
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'crs'
                ,clb_crs
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Add bbox on demand
      --------------------------------------------------------------------------
      IF str_add_bbox = 'TRUE'
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'bbox'
                ,self.bbox(
                     p_output_srid  => p_output_srid
                    ,p_prune_number => p_prune_number
                 )
                ,p_pretty_print + 1
             )
            ,p_pretty_print + 1
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Add Features
      --------------------------------------------------------------------------
      IF self.features IS NULL
      OR self.features.COUNT = 0
      THEN
         clb_features := 'null';
      
      ELSE
         boo_first := TRUE;
         FOR i IN 1 .. self.features.COUNT
         LOOP
            IF boo_first
            THEN
               clb_features := clb_features || dz_json_util.pretty(
                   str_pad || self.features(i).toJSON(
                       p_2d_flag      => p_2d_flag
                      ,p_pretty_print => p_pretty_print + 2
                      ,p_output_srid  => p_output_srid
                      ,p_prune_number => p_prune_number
                      ,p_add_crs      => 'FALSE'
                      ,p_add_bbox     => 'FALSE'
                   )
                  ,p_pretty_print + 2
               );
               boo_first := FALSE;
               
            ELSE
               clb_features := clb_features || dz_json_util.pretty(
                   ',' || self.features(i).toJSON(
                       p_2d_flag      => p_2d_flag
                      ,p_pretty_print => p_pretty_print + 2
                      ,p_output_srid  => p_output_srid
                      ,p_prune_number => p_prune_number
                      ,p_add_crs      => 'FALSE'
                      ,p_add_bbox     => 'FALSE'
                   )
                  ,p_pretty_print + 2
               );
               
            END IF;
         
         END LOOP;
         
         clb_features := clb_features || dz_json_util.pretty(
             ']'
            ,p_pretty_print + 1,NULL,NULL
         );
      
      END IF;
      
      clb_output := clb_output || dz_json_util.pretty(
          ',' || dz_json_main.formatted2json(
              'features'
             ,clb_features
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Add the left bracket
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          '}'
         ,p_pretty_print,NULL,NULL
      );
      
      --------------------------------------------------------------------------
      -- Step 80
      -- Return results
      --------------------------------------------------------------------------
      RETURN clb_output;
           
   END toJSON;
   
END;
/


--*************************--
PROMPT sqlplus_footer.sql;


SHOW ERROR;

DECLARE
   l_num_errors PLS_INTEGER;

BEGIN

   SELECT
   COUNT(*)
   INTO l_num_errors
   FROM
   user_errors a
   WHERE
   a.name LIKE 'DZ_JSON%';

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'COMPILE ERROR');

   END IF;

   l_num_errors := DZ_JSON_TEST.inmemory_test();

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'INMEMORY TEST ERROR');

   END IF;

END;
/

EXIT;

