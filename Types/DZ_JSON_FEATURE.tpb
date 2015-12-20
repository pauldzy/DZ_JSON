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

