CREATE OR REPLACE TYPE BODY dz_json_element1_obj
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element1_obj
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_json_element1_obj;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_json_element1_obj(
       p_elements   IN  dz_json_element1_vry
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.elements := p_elements;
      RETURN;
      
   END dz_json_element1_obj;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION toJSON(
      p_pretty_print     IN  NUMBER   DEFAULT NULL
   ) RETURN CLOB
   AS
      clb_output   CLOB;
      str_init     VARCHAR2(1 Char);
      str_pad      VARCHAR2(1 Char);
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Add the left bracket
      --------------------------------------------------------------------------
      IF p_pretty_print IS NULL
      THEN
         clb_output   := dz_json_util.pretty('{',NULL);
         str_pad      := '';
         
      ELSE
         clb_output   := dz_json_util.pretty('{',-1);
         str_pad      := ' ';
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Add elements
      --------------------------------------------------------------------------
      IF self.elements IS NOT NULL
      AND self.elements.COUNT > 0
      THEN
         str_init := str_pad;
         FOR i IN 1 .. self.elements.COUNT
         LOOP
            clb_output := clb_output || dz_json_util.pretty(
               str_init || '"' || self.elements(i).element_name || '":' || str_pad || self.elements(i).toJSON(
                  p_pretty_print => p_pretty_print + 1
               )
               ,p_pretty_print + 1
            );
            str_init := ',';
         
         END LOOP;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Add the left bracket
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
           
   END toJSON;
   
END;
/

