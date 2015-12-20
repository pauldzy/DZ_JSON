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

