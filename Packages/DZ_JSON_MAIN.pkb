CREATE OR REPLACE PACKAGE BODY dz_json_main 
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE geo_check(
       p_input            IN OUT MDSYS.SDO_GEOMETRY
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'  
      ,p_return_code      OUT NUMBER
      ,p_status_message   OUT VARCHAR2
   )
   AS
   
   BEGIN
   
      p_return_code := 0;
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check for NULL input, null input is okay, null srid is not
      --------------------------------------------------------------------------
      IF p_input IS NULL
      THEN
         p_status_message := 'Warning, input geometry is NULL';
         RETURN;
         
      END IF;
      
      IF p_input.SDO_SRID IS NULL
      THEN
         p_return_code    := -10;
         p_status_message := 'Error, input geometry must have coordinate system defined';
         RETURN;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Remove LRS measure and downsize if needed
      --------------------------------------------------------------------------
      IF  p_input.get_lrs_dim() <> 0
      THEN
         IF p_input.get_dims() = 2
         THEN
            p_input := dz_json_util.downsize_2d(p_input);
            
         ELSIF p_input.get_dims() = 3
         AND p_2d_flag = 'TRUE'
         THEN
            p_input := dz_json_util.downsize_2d(p_input);
            
         ELSIF p_input.get_dims() = 3
         AND p_2d_flag <> 'TRUE'
         THEN
            p_input := dz_json_util.downsize_3d(p_input);
            
         ELSE
            p_return_code    := -20;
            p_status_message := 'Error, unable to remove LRS dimension';
            RETURN;
            
         END IF;
         
      ELSE
         IF p_input.get_dims() = 3
         AND p_2d_flag = 'TRUE'
         THEN
            p_input := dz_json_util.downsize_2d(p_input);
            
         ELSIF p_input.get_dims() > 3
         THEN
            p_input := dz_json_util.downsize_3d(p_input);
            
         END IF;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Transform if not WGS84
      --------------------------------------------------------------------------
      IF p_input.SDO_SRID NOT IN (8307,4326)
      THEN
         p_input := MDSYS.SDO_CS.TRANSFORM(p_input,4326);
      
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Break if geometry crosses antimeridian
      --------------------------------------------------------------------------
      -- To be done
   
   END geo_check;

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
   
      str_output := str_output || '[' || json_format(dz_json_util.prune_number(
          p_input => p_input.x
         ,p_trunc => p_prune_number
      )) || ',' || json_format(dz_json_util.prune_number(
          p_input => p_input.y
         ,p_trunc => p_prune_number
      ));
                 
      IF p_input.z IS NOT NULL
      AND p_2d_flag = 'FALSE'
      THEN
         str_output := str_output || ',' || json_format(dz_json_util.prune_number(
             p_input => p_input.z
            ,p_trunc => p_prune_number
         ));
         
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
      
      str_output := str_output || '[' || json_format(dz_json_util.prune_number(
          p_input => p_input.SDO_ORDINATES(1)
         ,p_trunc => p_prune_number
      )) || ',' || json_format(dz_json_util.prune_number(
          p_input => p_input.SDO_ORDINATES(2)
         ,p_trunc => p_prune_number
      ));
      
      IF  int_dims > 2
      AND p_2d_flag = 'FALSE'
      THEN
         str_output := str_output || ',' || json_format(dz_json_util.prune_number(p_input.SDO_ORDINATES(3),16));
         
      END IF;
      
      IF  int_dims > 3
      AND p_2d_flag = 'FALSE'
      THEN
         str_output := str_output || ',' || json_format(dz_json_util.prune_number(p_input.SDO_ORDINATES(4),16));
         
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
                '[' || json_format(dz_json_util.prune_number(
                    p_input => p_input.SDO_ORDINATES(int_counter)
                   ,p_trunc => p_prune_number
                )
            ));
            
            int_counter := int_counter + 1;
            
            clb_vertice := clb_vertice || TO_CLOB(
                ',' || json_format(dz_json_util.prune_number(
                    p_input => p_input.SDO_ORDINATES(int_counter)
                   ,p_trunc => p_prune_number
                )
            ));
            
            int_counter := int_counter + 1;

            IF int_dims > 2
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_vertice := clb_vertice || TO_CLOB(
                      ',' || json_format(dz_json_util.prune_number(
                          p_input => p_input.SDO_ORDINATES(int_counter)
                         ,p_trunc => p_prune_number
                      )
                  ));
                  
               END IF;
               
               int_counter := int_counter + 1;
               
            END IF;
         
            IF int_dims > 3
            THEN
               IF p_2d_flag = 'FALSE'
               THEN
                  clb_vertice := clb_vertice || TO_CLOB(
                      ',' || json_format(dz_json_util.prune_number(
                          p_input => p_input.SDO_ORDINATES(int_counter)
                         ,p_trunc => p_prune_number
                      )
                  ));
                  
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
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            )) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                str_pad || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            )) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            )) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            )) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            )) || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
  
         ELSIF int_dims = 3
         THEN
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               ));
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               ));
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(5)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(6)
                  ,p_trunc => p_prune_number
               ));
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(5)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(6)
                  ,p_trunc => p_prune_number
               ));
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               ));
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
         ELSIF int_dims = 4
         THEN
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               )) || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(4)
                  ,p_trunc => p_prune_number
               ));
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(5)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               )) || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(4)
                  ,p_trunc => p_prune_number
               ));
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(5)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(6)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(7)
                  ,p_trunc => p_prune_number
               )) || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(8)
                  ,p_trunc => p_prune_number
               ));
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(6)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(7)
                  ,p_trunc => p_prune_number
               )) || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(8)
                  ,p_trunc => p_prune_number
               ));
               
            END IF;
            
            clb_vertice := clb_vertice || ']';
            
            clb_output := clb_output || dz_json_util.pretty(
                ',' || clb_vertice
               ,p_pretty_print + 1
            );
            
            clb_vertice := '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            ));
            
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(3)
                  ,p_trunc => p_prune_number
               )) || ',' || json_format(dz_json_util.prune_number(
                   p_input => p_input.SDO_ORDINATES(4)
                  ,p_trunc => p_prune_number
               ));
               
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
            '[' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(int_counter)
               ,p_trunc => p_prune_number
            )
         ));
         int_counter := int_counter + 1;
            
         clb_vertice  := clb_vertice || TO_CLOB(
            ',' || json_format(dz_json_util.prune_number(
                p_input => p_input.SDO_ORDINATES(int_counter)
               ,p_trunc => p_prune_number
            )
         ));
         int_counter := int_counter + 1;

         IF int_dims > 2
         THEN
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || TO_CLOB(
                  ',' || json_format(dz_json_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(int_counter)
                     ,p_trunc => p_prune_number
                  ))
               );
               
            END IF;
            
            int_counter := int_counter + 1;
         
         END IF;
         
         IF int_dims > 3
         THEN
            IF p_2d_flag = 'FALSE'
            THEN
               clb_vertice := clb_vertice || TO_CLOB(
                  ',' || json_format(dz_json_util.prune_number(
                      p_input => p_input.SDO_ORDINATES(int_counter)
                     ,p_trunc => p_prune_number
                  ))
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
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      sdo_input          MDSYS.SDO_GEOMETRY := p_input;
      str_2d_flag        VARCHAR2(5 Char)  := UPPER(p_2d_flag);
      num_return_code    NUMBER;
      str_status_message VARCHAR2(4000 Char);
      int_gtype          PLS_INTEGER;
      int_dims           PLS_INTEGER;
      int_lrs            PLS_INTEGER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------   
      IF sdo_input IS NULL
      THEN
         RETURN 'null';
         
      END IF;
   
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'FALSE';
         
      ELSIF str_2d_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_2d_flag parameter can only be TRUE or FALSE'
         );
         
      END IF;
         
      --------------------------------------------------------------------------
      -- Step 20
      -- Process the geometry
      --------------------------------------------------------------------------   
      geo_check(
          p_input            => sdo_input
         ,p_2d_flag          => str_2d_flag  
         ,p_return_code      => num_return_code
         ,p_status_message   => str_status_message
      );
      IF num_return_code <> 0
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,str_status_message
         );
      
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
      
      IF sdo_input IS NOT NULL
      AND sdo_input.SDO_SRID NOT IN (8307,4326)
      THEN
         sdo_input := MDSYS.SDO_CS.TRANSFORM(sdo_input,4326);
         
      END IF;
      
      sdo_mbr_geom := MDSYS.SDO_GEOM.SDO_MBR(
         geom => sdo_input
      );
         
      IF sdo_mbr_geom.get_gtype() = 3
      THEN
         RETURN '[' ||
            json_format(dz_json_util.prune_number(
                p_input => sdo_mbr_geom.SDO_ORDINATES(1)
               ,p_trunc => p_prune_number
            )) || ',' ||
            json_format(dz_json_util.prune_number(
                p_input => sdo_mbr_geom.SDO_ORDINATES(2)
               ,p_trunc => p_prune_number
            )) || ',' ||
            json_format(dz_json_util.prune_number(
                p_input => sdo_mbr_geom.SDO_ORDINATES(3)
               ,p_trunc => p_prune_number
            )) || ',' ||
            json_format(dz_json_util.prune_number(
                p_input => sdo_mbr_geom.SDO_ORDINATES(4)
               ,p_trunc => p_prune_number
            )) ||
         ']';
         
      ELSE
         RETURN 'null';
            
      END IF;
         
   END sdo2bbox;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sdo2geojson_feature(
       p_input            IN  MDSYS.SDO_GEOMETRY
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_2d_flag          IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_add_bbox         IN  VARCHAR2 DEFAULT 'FALSE'
      ,p_properties       IN  CLOB     DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_output         CLOB := '';
      str_add_bbox       VARCHAR2(4000 Char) := UPPER(p_add_bbox);
      str_2d_flag        VARCHAR2(5 Char)    := UPPER(p_2d_flag);
      num_return_code    NUMBER;
      str_status_message VARCHAR2(4000 Char);
      str_pad            VARCHAR2(1 Char);
      sdo_input          MDSYS.SDO_GEOMETRY := p_input;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_add_bbox IS NULL
      THEN
         str_add_bbox := 'FALSE';
         
      ELSIF str_add_bbox NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'FALSE';
         
      ELSIF str_2d_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'p_2d_flag parameter can only be TRUE or FALSE'
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Process the geometry
      --------------------------------------------------------------------------
      geo_check(
          p_input            => sdo_input
         ,p_2d_flag          => str_2d_flag  
         ,p_return_code      => num_return_code
         ,p_status_message   => str_status_message
      );
      IF num_return_code <> 0
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,str_status_message
         );
      
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
      -- Add bbox on demand
      --------------------------------------------------------------------------
      IF str_add_bbox = 'TRUE'
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'bbox'
                ,sdo2bbox(
                     p_input        => sdo_input
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
             REGEXP_REPLACE(str_output,CHR(13),'')
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
         
         str_output := REGEXP_REPLACE(
             str_output
            ,CHR(21)
            ,'\u0015'
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
             REGEXP_REPLACE(clb_output,CHR(13),'')
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
         
         clb_output := REGEXP_REPLACE(
             clb_output
            ,CHR(21)
            ,'\u0015'
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
      ,p_input            IN  BOOLEAN
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
   BEGIN
      IF p_input
      THEN
         RETURN TO_CLOB(
            fastname(
             p_name
            ,p_pretty_print
         ) || 'true');
         
      ELSE
         RETURN TO_CLOB(
            fastname(
             p_name
            ,p_pretty_print
         ) || 'false');
      
      END IF;      
   
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
      str_pad    VARCHAR2(1 Char);

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
      str_pad := ' ';
      FOR i IN 1 .. p_input.COUNT
      LOOP
         clb_output := clb_output || dz_json_util.pretty(
             str_pad || json_format(p_input(i))
            ,p_pretty_print + 1
         );

         str_pad := ',';

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
      str_pad    VARCHAR2(1 Char);

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
         clb_output := clb_output || dz_json_util.pretty('[',NULL);

      ELSE
         clb_output := clb_output || dz_json_util.pretty('[',-1);

      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Spin out the values
      --------------------------------------------------------------------------
      str_pad := ' ';
      FOR i IN 1 .. p_input.COUNT
      LOOP
         clb_output := clb_output || dz_json_util.pretty(
             str_pad || json_format(p_input(i))
            ,p_pretty_print + 1
         );

         str_pad := ',';

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

