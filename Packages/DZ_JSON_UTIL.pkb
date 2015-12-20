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

