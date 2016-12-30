CREATE OR REPLACE TYPE BODY dz_json_element3
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element3
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_json_element3;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element3(
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
      
   END dz_json_element3;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element3(
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
      
   END dz_json_element3;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element3(
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
      
   END dz_json_element3;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element3(
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
      
   END dz_json_element3;
   
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
      
      IF  self.element_string  IS NULL
      AND self.element_number  IS NULL
      AND self.element_date    IS NULL
      AND self.element_complex IS NULL
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
      -- Complex output
      --------------------------------------------------------------------------
      IF self.element_complex IS NOT NULL
      THEN
         RETURN self.element_complex;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 70
      -- Element must be null
      --------------------------------------------------------------------------
      RETURN 'null';
           
   END toJSON;
   
END;
/

