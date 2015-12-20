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

