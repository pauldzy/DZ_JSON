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
   MEMBER FUNCTION toJSON(
       p_2d_flag          IN  VARCHAR2 DEFAULT 'TRUE'
      ,p_pretty_print     IN  NUMBER   DEFAULT NULL
      ,p_prune_number     IN  NUMBER   DEFAULT NULL
      ,p_add_bbox         IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN CLOB
   AS
      clb_output     CLOB;
      clb_properties CLOB;
      str_2d_flag    VARCHAR2(4000 Char) := UPPER(p_2d_flag);
      str_add_bbox   VARCHAR2(4000 Char) := UPPER(p_add_bbox);
      str_init       VARCHAR2(1 Char);
      str_init2      VARCHAR2(1 Char);
      str_pad        VARCHAR2(1 Char);
      sdo_input      MDSYS.SDO_GEOMETRY;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Check incoming parameters
      --------------------------------------------------------------------------
      IF str_2d_flag IS NULL
      THEN
         str_2d_flag := 'FALSE';
         
      ELSIF str_2d_flag NOT IN ('FALSE','TRUE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      IF str_add_bbox IS NULL
      THEN
         str_add_bbox := 'FALSE';
         
      ELSIF str_add_bbox NOT IN ('FALSE','TRUE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Transform if required
      --------------------------------------------------------------------------
      IF  self.geometry IS NOT NULL
      AND self.geometry.SDO_SRID NOT IN (4326,8307)
      THEN
         sdo_input := MDSYS.SDO_CS.TRANSFORM(
             self.geometry
            ,4326
         );
       
      ELSE
         sdo_input := self.geometry;
      
      END IF;
  
      --------------------------------------------------------------------------
      -- Step 30
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
      
      str_init := str_pad;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Build the object basics
      --------------------------------------------------------------------------
      clb_output := clb_output || dz_json_util.pretty(
          str_init || dz_json_main.value2json(
              'type'
             ,'Feature'
             ,p_pretty_print + 1
          )
         ,p_pretty_print + 1
      );
      str_init := ',';
      
      --------------------------------------------------------------------------
      -- Step 50
      -- Add bbox on demand
      --------------------------------------------------------------------------
      IF str_add_bbox = 'TRUE'
      THEN
         clb_output := clb_output || dz_json_util.pretty(
             str_init || dz_json_main.formatted2json(
                'bbox'
               ,dz_json_main.sdo2bbox(
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
          str_init || dz_json_main.formatted2json(
             'geometry'
            ,dz_json_main.sdo2geojson(
                p_input        => sdo_input
               ,p_pretty_print => p_pretty_print + 1
               ,p_2d_flag      => str_2d_flag
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
         clb_output := clb_output || dz_json_util.pretty(
             str_init || '"properties":' || str_pad || 'null'
            ,p_pretty_print + 1
         );
      
      ELSE
         str_init2 := str_pad;
         FOR i IN 1 .. self.properties.COUNT
         LOOP
            clb_properties := clb_properties || dz_json_util.pretty(
                str_init2 || '"' || self.properties(i).properties_name || '":' || str_pad || self.properties(i).toJSON(
                   p_pretty_print => p_pretty_print + 2
                )
               ,p_pretty_print + 2
            );
            str_init2 := ',';
         
         END LOOP;
         
         clb_properties := clb_properties || dz_json_util.pretty(
             '}'
            ,p_pretty_print + 1,NULL,NULL
         );
         
         clb_output := clb_output || dz_json_util.pretty(
             ',' || dz_json_main.formatted2json(
                 'properties'
                ,clb_properties
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
           
   END toJSON;
   
END;
/

