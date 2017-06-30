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
      ,p_properties_clob    IN  CLOB
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_properties_clob IS NULL
      THEN
         self.properties_null := 1;
         
      ELSE
         self.properties_clob := p_properties_clob;
         
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
   CONSTRUCTOR FUNCTION dz_json_properties(
       p_name                IN  VARCHAR2
      ,p_properties_element  IN  dz_json_element1_obj
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      IF p_properties_element IS NULL
      THEN
         self.properties_null := 1;
         
      ELSE
         self.properties_element := p_properties_element;
         
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
      
      IF  self.properties_string  IS NULL
      AND self.properties_clob    IS NULL
      AND self.properties_number  IS NULL
      AND self.properties_date    IS NULL
      AND self.properties_complex IS NULL
      AND self.properties_element IS NULL
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
      num_pretty_print NUMBER := p_pretty_print;
      
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
      IF self.properties_string IS NOT NULL
      THEN
         RETURN dz_json_main.json_format(
            p_input        => self.properties_string
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Clob output
      --------------------------------------------------------------------------
      IF self.properties_clob IS NOT NULL
      THEN
         RETURN dz_json_main.json_format(
            p_input        => self.properties_clob
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Number output
      --------------------------------------------------------------------------
      IF self.properties_number IS NOT NULL
      THEN
         RETURN dz_json_main.json_format(
            p_input        => self.properties_number
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Date output
      --------------------------------------------------------------------------
      IF self.properties_date IS NOT NULL
      THEN
         RETURN dz_json_main.json_format(
            p_input        => self.properties_date
         );
         
      END IF;
   
      --------------------------------------------------------------------------
      -- Step 60
      -- Complex output
      --------------------------------------------------------------------------
      IF self.properties_complex IS NOT NULL
      THEN
         RETURN self.properties_complex;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Subobject output
      --------------------------------------------------------------------------
      IF self.properties_element IS NOT NULL
      THEN
         RETURN self.properties_element.toJSON(
            p_pretty_print => num_pretty_print
         );
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 80
      -- Element must be null
      --------------------------------------------------------------------------
      RETURN 'null';
   
   END toJSON;
   
END;
/

