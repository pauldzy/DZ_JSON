CREATE OR REPLACE TYPE BODY dz_json_element2
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name               IN  VARCHAR2
      ,p_element_string     IN  VARCHAR2
   ) RETURN SELF AS RESULT
   AS
   BEGIN
   
      IF p_element_string IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_string := p_element_string;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name               IN  VARCHAR2
      ,p_element_number     IN  NUMBER
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_element_number IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_number := p_element_number;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name               IN  VARCHAR2
      ,p_element_date       IN  DATE
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_element_date IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_date := p_element_date;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_string_vry  IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_element_string_vry IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_string_vry := p_element_string_vry;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_number_vry  IN  MDSYS.SDO_NUMBER_ARRAY
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_element_number_vry IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_number_vry := p_element_number_vry;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name               IN  VARCHAR2
      ,p_element_clob       IN  CLOB
   ) RETURN SELF AS RESULT
   AS
   BEGIN
   
      IF p_element_clob IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_clob := p_element_clob;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name               IN  VARCHAR2
      ,p_element_complex    IN  CLOB
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_element_complex IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_complex := p_element_complex;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name               IN  VARCHAR2
      ,p_element_obj        IN  dz_json_element3_obj
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_element_obj IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_obj := p_element_obj;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name               IN  VARCHAR2
      ,p_element_vry        IN  dz_json_element3_vry
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_element_vry IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_vry := p_element_vry;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element2(
       p_name                IN  VARCHAR2
      ,p_element_obj_vry     IN  dz_json_element3_obj_vry
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_element_obj_vry IS NULL
      THEN
         self.element_null := 1;
         
      ELSE
         self.element_obj_vry := p_element_obj_vry;
         
      END IF;
      
      self.element_name := p_name;
      
      RETURN;
      
   END dz_json_element2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION isNULL
   RETURN VARCHAR2
   AS
   BEGIN
      IF self.element_null = 1
      THEN
         RETURN 'TRUE';
         
      END IF;
      
      IF  self.element_string     IS NULL
      AND self.element_number     IS NULL
      AND self.element_date       IS NULL
      AND self.element_clob       IS NULL
      AND self.element_complex    IS NULL
      AND self.element_obj        IS NULL
      AND ( 
         self.element_vry IS NULL
         OR self.element_vry.COUNT = 0 
      )
      AND ( 
         self.element_obj_vry IS NULL
         OR self.element_obj_vry.COUNT = 0 
      )
      AND ( 
         self.element_string_vry IS NULL
         OR self.element_string_vry.COUNT = 0 
      )
      AND ( 
         self.element_number_vry IS NULL
         OR self.element_number_vry.COUNT = 0 
      )
      THEN
         RETURN 'TRUE';
         
      END IF;
      
      RETURN 'FALSE';
      
   END isNULL;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION toJSON(
      p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_vry          CLOB;
      num_pretty_print NUMBER := p_pretty_print;
      str_pad          VARCHAR2(1 Char);
      str_init         VARCHAR2(1 Char);
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Account for null
      --------------------------------------------------------------------------
      IF self.isNULL() = 'TRUE'
      THEN
         RETURN 'null';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- String output
      --------------------------------------------------------------------------
      IF self.element_string IS NOT NULL
      THEN
         RETURN dz_json_main.json_format(
             p_input        => self.element_string
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Number output
      --------------------------------------------------------------------------
      IF self.element_number IS NOT NULL
      THEN
         RETURN dz_json_main.json_format(
             p_input        => self.element_number
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Date output
      --------------------------------------------------------------------------
      IF self.element_date IS NOT NULL
      THEN
         RETURN dz_json_main.json_format(
             p_input        => self.element_date
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 60
      -- String Array output
      --------------------------------------------------------------------------
      IF self.element_string_vry IS NOT NULL
      THEN
         IF num_pretty_print IS NULL
         THEN
            clb_vry := dz_json_util.pretty('[',NULL);
            str_pad := '';
            
         ELSE
            clb_vry := dz_json_util.pretty('[',-1);
            str_pad := ' ';
            
         END IF;
         str_init := str_pad;
         
         FOR i IN 1 .. self.element_string_vry.COUNT
         LOOP
            clb_vry := clb_vry || dz_json_util.pretty(
                str_init || dz_json_main.json_format(self.element_string_vry(i))
               ,num_pretty_print + 1
            );
            str_init := ',';
           
         END LOOP;
         
         clb_vry := clb_vry || dz_json_util.pretty(
             ']'
            ,num_pretty_print,NULL,NULL
         );
      
         RETURN clb_vry;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Number Array output
      --------------------------------------------------------------------------
      IF self.element_number_vry IS NOT NULL
      THEN
         IF num_pretty_print IS NULL
         THEN
            clb_vry := dz_json_util.pretty('[',NULL);
            str_pad := '';
            
         ELSE
            clb_vry := dz_json_util.pretty('[',-1);
            str_pad := ' ';
            
         END IF;
         str_init := str_pad;
         
         FOR i IN 1 .. self.element_number_vry.COUNT
         LOOP
            clb_vry := clb_vry || dz_json_util.pretty(
                str_init || dz_json_main.json_format(self.element_number_vry(i))
               ,num_pretty_print + 1
            );
            str_init := ',';
           
         END LOOP;
         
         clb_vry := clb_vry || dz_json_util.pretty(
             ']'
            ,num_pretty_print,NULL,NULL
         );
      
         RETURN clb_vry;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 80
      -- Clob output
      --------------------------------------------------------------------------
      IF self.element_clob IS NOT NULL
      THEN
         RETURN dz_json_main.json_format(
             p_input        => self.element_clob
         );
         
      END IF;
   
      --------------------------------------------------------------------------
      -- Step 90
      -- Complex output
      --------------------------------------------------------------------------
      IF self.element_complex IS NOT NULL
      THEN
         RETURN self.element_complex;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 100
      -- Subobject output
      --------------------------------------------------------------------------
      IF self.element_obj IS NOT NULL
      THEN
         RETURN self.element_obj.toJSON(
            p_pretty_print => num_pretty_print
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 110
      -- Subobject output
      --------------------------------------------------------------------------
      IF self.element_vry IS NOT NULL
      THEN
         IF p_pretty_print IS NULL
         THEN
            clb_vry := dz_json_util.pretty('[',NULL);
            str_pad := '';
            
         ELSE
            clb_vry := dz_json_util.pretty('[',-1);
            str_pad := ' ';
            
         END IF;
         str_init := str_pad;
         
         FOR i IN 1 .. self.element_vry.COUNT
         LOOP
            clb_vry := clb_vry || dz_json_util.pretty(
                str_init || self.element_vry(i).toJSON(
                  p_pretty_print => p_pretty_print + 1
                )
               ,p_pretty_print + 1
            );
            str_init := ',';
           
         END LOOP;
         
         clb_vry := clb_vry || dz_json_util.pretty(
             ']'
            ,p_pretty_print,NULL,NULL
         );
      
         RETURN clb_vry;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 120
      -- Subobject output
      --------------------------------------------------------------------------
      IF self.element_obj_vry IS NOT NULL
      THEN
         IF p_pretty_print IS NULL
         THEN
            clb_vry := dz_json_util.pretty('[',NULL);
            str_pad := '';
            
         ELSE
            clb_vry := dz_json_util.pretty('[',-1);
            str_pad := ' ';
            
         END IF;
         str_init := str_pad;
         
         FOR i IN 1 .. self.element_obj_vry.COUNT
         LOOP
            clb_vry := clb_vry || dz_json_util.pretty(
                str_init || self.element_obj_vry(i).toJSON(
                  p_pretty_print => p_pretty_print + 1
                )
               ,p_pretty_print + 1
            );
            str_init := ',';
           
         END LOOP;
         
         clb_vry := clb_vry || dz_json_util.pretty(
             ']'
            ,p_pretty_print,NULL,NULL
         );
      
         RETURN clb_vry;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 130
      -- Element must be null
      --------------------------------------------------------------------------
      RETURN 'null';
           
   END toJSON;
   
END;
/

