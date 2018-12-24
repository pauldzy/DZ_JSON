# DZ_JSON
Utilities for the creation of JSON and GeoJSON from Oracle data types and structures.  Release 2.0 targets changes to the GeoJSON specification as published in August 2016 as [RFC 7946](https://tools.ietf.org/html/rfc7946).

For the most up-to-date documentation see the auto-build [dz_json_deploy.pdf](https://github.com/pauldzy/DZ_JSON/blob/master/dz_json_deploy.pdf).

Note these packages were created in the Oracle 10g days to transform Oracle and Oracle Spatial objects into JSON with GeoJSON as CLOBs to then drive REST-like sevices via mod_plsql.  While the intention always was to include JSON to SDO geometry conversion functionality, the code **currently** does not provide this, e.g. this only converts SDO to GeoJSON and not the other way around.  Adding JSON conversion would ideally harness the new JSON handling in 12c.  However as of 12cR1 JSON deserialization is limited to string values of 4000 characters or less which makes processing geometry somewhat limited.  

#### GeoJSON Geometry Conversion Examples:

2D Point
```sql
SELECT  
dz_json_main.sdo2geojson(
   p_input  => MDSYS.SDO_GEOMETRY(2001,8307,MDSYS.SDO_POINT_TYPE(-79,37,NULL),NULL,NULL) 
)  
FROM  
dual;

>> {"type":"Point","coordinates":[-79,37]}
```

2D Polygon
```sql
SELECT
dz_json_main.sdo2geojson(
   p_input  => MDSYS.SDO_GEOMETRY(
       2003
      ,4326
      ,NULL
      ,MDSYS.SDO_ELEM_INFO_ARRAY(1,1003,1)
      ,MDSYS.SDO_ORDINATE_ARRAY(5,1, 8,1, 8,6, 5,7, 5,1)
  ) 
)  
FROM  
dual;

>> {"type":"Polygon","coordinates":[[[5,1],[8,1],[8,6],[5,7],[5,1]]]]}
```

3D Point
```sql
SELECT  
dz_json_main.sdo2geojson(
   p_input  => MDSYS.SDO_GEOMETRY(3001,4326,MDSYS.SDO_POINT_TYPE(-79,37,200),NULL,NULL) 
)  
FROM  
dual;

>> {"type":"Point","coordinates":[-79,37,200]}
```

#### GeoJSON Feature Conversion Example:

3D Point with properties and numeric precision pruning

```sql
SELECT  
dz_json_feature(  
    p_geometry => MDSYS.SDO_GEOMETRY(
         3001
        ,8265
        ,MDSYS.SDO_POINT_TYPE(-65.12345678901234567890,41.12345678901234567890,88.12345678901234567890)
        ,NULL
        ,NULL
    )  
   ,p_properties => dz_json_properties_vry(  
        dz_json_properties(  
            p_name => 'FeatureID'  
           ,p_properties_number => 1234  
        )  
       ,dz_json_properties(  
            p_name => 'FriedChickenStyle'  
           ,p_properties_string => 'Southern'  
        )  
       ,dz_json_properties(  
            p_name => 'AverageCostOfLemonade'  
           ,p_properties_number => 4.32  
        )  
    )   
).toJSON(  
    p_2d_flag       => 'FALSE'  
   ,p_pretty_print  => 0  
   ,p_prune_number  => 8  
   ,p_add_bbox      => 'FALSE'  
)  
FROM dual;

>> {
    "type": "Feature"
   ,"geometry": {
       "type": "Point"
      ,"coordinates": [-65.12345678,41.12345678,88.12345678]
   }
   ,"properties": {
       "FeatureID": 1234
      ,"FriedChickenStyle": "Southern"
      ,"AverageCostOfLemonade": 4.32
   }
}
```

#### DZ_TESTDATA Examples

[DZ_TESTDATA](https://github.com/pauldzy/DZ_TESTDATA) provides a sampling of real Oracle Spatial data for testing purposes.  The following examples harness these datasets for their examples.

Points to Geometries
```
SELECT
dz_json_main.sdo2geojson(
   p_input  => a.shape
)  
FROM  
osm_kenosha_poi a
WHERE
a.amenity = 'car_wash';

>> {"type":"Point","coordinates":[-87.8439887300383,42.5656672831262]}
>> {"type":"Point","coordinates":[-87.8827483209174,42.5674485712746]}
>> {"type":"Point","coordinates":[-87.8809925,42.5882576]}
>> {"type":"Point","coordinates":[-87.8732731,42.6026928]}
```

Points to Features
```
SELECT  
dz_json_feature(  
    p_geometry => a.shape 
   ,p_properties => dz_json_properties_vry(  
        dz_json_properties(  
            p_name => 'OSMID'  
           ,p_properties_number => a.osm_id
        )  
       ,dz_json_properties(  
            p_name => 'OSMName'  
           ,p_properties_number => a.osm_name
        ) 
       ,dz_json_properties(  
            p_name => 'Amenity'  
           ,p_properties_number => a.amenity 
        )  
    )   
).toJSON(  
    p_prune_number  => 8  
)  
FROM 
osm_kenosha_poi a
WHERE
a.amenity = 'library';

>> {"type":"Feature","geometry":{"type":"Point","coordinates":[-87.8389638,42.5775202]},"properties":{"OSMID":"node/367808832","OSMName":"Uptown Branch Kenosha Public Library","Amenity":"library"}}
>> {"type":"Feature","geometry":{"type":"Point","coordinates":[-87.85317883,42.55946147]},"properties":{"OSMID":"way/114702549","OSMName":"Southwest Branch Kenosha Public Library","Amenity":"library"}}
>> {"type":"Feature","geometry":{"type":"Point","coordinates":[-87.85503669,42.64546695]},"properties":{"OSMID":"way/190909779","OSMName":"Wyllie Hall","Amenity":"library"}}
>> {"type":"Feature","geometry":{"type":"Point","coordinates":[-87.84262823,42.63197855]},"properties":{"OSMID":"way/220675891","OSMName":"Northside Public Library","Amenity":"library"}}
>> {"type":"Feature","geometry":{"type":"Point","coordinates":[-87.8193886,42.58055535]},"properties":{"OSMID":"way/220680358","OSMName":"Gilbert M Simmons Branch","Amenity":"library"}}
>> {"type":"Feature","geometry":{"type":"Point","coordinates":[-87.820908,42.6227979]},"properties":{"OSMID":"node/367808937","OSMName":"Hedberg Library","Amenity":"library"}}
>> {"type":"Feature","geometry":{"type":"Point","coordinates":[-87.820908,42.6227979]},"properties":{"OSMID":"node/367808937","OSMName":"Hedberg Library","Amenity":"library"}}
```

Points to Feature Collection
```
SELECT
dz_json_feature_collection(
   features => CAST(MULTISET(
      SELECT
      dz_json_feature(  
          p_geometry => a.shape
         ,p_properties => dz_json_properties_vry(  
              dz_json_properties(  
                  p_name => 'OSMID'  
                 ,p_properties_string => a.osm_id
              )
              ,dz_json_properties(  
                  p_name => 'OSMName'  
                 ,p_properties_string => a.osm_name
              )
              ,dz_json_properties(  
                  p_name => 'Amenity'  
                 ,p_properties_string => a.amenity
              )
          )   
      )
      FROM 
      osm_kenosha_poi a
      WHERE
      a.amenity = 'hospital'
  ) AS dz_json_feature_vry)
).toJSON(  
    p_prune_number  => 8  
) AS feature_collection
FROM dual;

>> {"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[-87.8231299,42.5744647]},"properties":{"OSMID":"node/349525251","OSMName":"Doctors Park Clinic","Amenity":"hospital"}},{"type":"Feature","geometry":{"type":"Point","coordinates":[-87.93537969,42.56981226]},"properties":{"OSMID":"way/191812031","OSMName":"Aurora Medical Center","Amenity":"hospital"}},{"type":"Feature","geometry":{"type":"Point","coordinates":[-87.92453868,42.56461254]},"properties":{"OSMID":"way/220685680","OSMName":"St. Catherine's Hospital","Amenity":"hospital"}},{"type":"Feature","geometry":{"type":"Point","coordinates":[-87.820352,42.5775203]},"properties":{"OSMID":"node/349525228","OSMName":"Kenosha Hospital","Amenity":"hospital"}}]}
```

Polygons to Feature Collection
```
SELECT
dz_json_feature_collection(
   features => CAST(MULTISET(
      SELECT
      dz_json_feature(  
          p_geometry => a.shape
         ,p_properties => dz_json_properties_vry(  
              dz_json_properties(  
                  p_name => 'PermanentIdentifier'  
                 ,p_properties_string => a.permanent_identifier
              )
              ,dz_json_properties(  
                  p_name => 'ReachCode'  
                 ,p_properties_string => a.reachcode
              )
              ,dz_json_properties(  
                  p_name => 'GNISName'  
                 ,p_properties_string => a.gnis_name
              )
              ,dz_json_properties(  
                  p_name => 'AreaSqKm'  
                 ,p_properties_number => a.areasqkm
              )
          )   
      )
      FROM 
      nhdplus21_nhdwaterbody_55059 a
      WHERE
          a.gnis_id IS NOT NULL
      AND rownum <= 3
  ) AS dz_json_feature_vry)
).toJSON(  
    p_pretty_print  => 0
   ,p_prune_number  => 8 
   ,p_add_bbox      => 'TRUE' 
) AS feature_collection
FROM dual;

>> {
    "type": "FeatureCollection"
   ,"bbox": [-88.29908237,42.50010106,-88.0350069,42.61258519]
   ,"features": [
       {
          "type": "Feature"
         ,"geometry": {
             "type": "Polygon"
            ,"coordinates": [
                [
                   [-88.2968721,42.60374346]
                  ,[-88.2963925,42.60363119]
                  ,[-88.2947515,42.60365286]
                  ,[-88.2926767,42.60401746]
                  ,[-88.29187157,42.60408559]
                  ,[-88.29168557,42.60424546]
                  ,[-88.29131337,42.60479419]
                  ,[-88.29115797,42.60527426]
                  ,[-88.2910949,42.60612059]
                  ,[-88.29118777,42.60618919]
                  ,[-88.29121797,42.60671539]
                  ,[-88.2919303,42.60657846]
                  ,[-88.29211637,42.60637279]
                  ,[-88.29254997,42.60619019]
                  ,[-88.2927977,42.60621319]
                  ,[-88.2933237,42.60644226]
                  ,[-88.2934783,42.60657959]
                  ,[-88.29366377,42.60685426]
                  ,[-88.2940969,42.60719759]
                  ,[-88.29428217,42.60751786]
                  ,[-88.2944059,42.60760946]
                  ,[-88.2956753,42.60779326]
                  ,[-88.29669677,42.60797699]
                  ,[-88.2972231,42.60795446]
                  ,[-88.2979047,42.60770326]
                  ,[-88.2985553,42.60733779]
                  ,[-88.29883417,42.60706346]
                  ,[-88.29908237,42.60660626]
                  ,[-88.2990517,42.60642326]
                  ,[-88.29895897,42.60633166]
                  ,[-88.29892957,42.60505086]
                  ,[-88.2986515,42.60452466]
                  ,[-88.29824937,42.60422706]
                  ,[-88.2969805,42.60376886]
                  ,[-88.2968721,42.60374346]
               ]
            ]
         }
         ,"properties": {
             "PermanentIdentifier": "14768008"
            ,"ReachCode": "07120006001630"
            ,"GNISName": "Dyer Lake"
            ,"AreaSqKm": 0.23475818403
         }
      }
      ,{
          "type": "Feature"
         ,"geometry": {
             "type": "Polygon"
            ,"coordinates": [
                [
                   [-88.1801079,42.61027459]
                  ,[-88.1793029,42.61036639]
                  ,[-88.1781883,42.61038986]
                  ,[-88.17797157,42.61048139]
                  ,[-88.17784797,42.61077879]
                  ,[-88.17806537,42.61148766]
                  ,[-88.17849957,42.61231086]
                  ,[-88.1788405,42.61258519]
                  ,[-88.1792739,42.61258499]
                  ,[-88.17949057,42.61251626]
                  ,[-88.17992377,42.61212726]
                  ,[-88.1802331,42.61166966]
                  ,[-88.1803569,42.61160086]
                  ,[-88.18078977,42.61093746]
                  ,[-88.18072737,42.61054866]
                  ,[-88.1802627,42.61027439]
                  ,[-88.1801079,42.61027459]
               ]
            ]
         }
         ,"properties": {
             "PermanentIdentifier": "14768002"
            ,"ReachCode": "07120006001628"
            ,"GNISName": "Flanagan Lake"
            ,"AreaSqKm": 0.04367565203
         }
      }
      ,{
          "type": "Feature"
         ,"geometry": {
             "type": "Polygon"
            ,"coordinates": [
                [
                   [-88.0367971,42.50328086]
                  ,[-88.0372609,42.50314386]
                  ,[-88.0380655,42.50250419]
                  ,[-88.03865377,42.50179546]
                  ,[-88.03865477,42.50115506]
                  ,[-88.03859297,42.50106346]
                  ,[-88.0385623,42.50092626]
                  ,[-88.03825357,42.50058299]
                  ,[-88.0376669,42.50017066]
                  ,[-88.0370487,42.50012459]
                  ,[-88.03621417,42.50010106]
                  ,[-88.03562657,42.50035226]
                  ,[-88.03522417,42.50069499]
                  ,[-88.03500737,42.50101506]
                  ,[-88.0350069,42.50142666]
                  ,[-88.0351609,42.50179286]
                  ,[-88.03528417,42.50204459]
                  ,[-88.0353149,42.50213606]
                  ,[-88.03577777,42.50275399]
                  ,[-88.0362409,42.50307446]
                  ,[-88.0367045,42.50318926]
                  ,[-88.0367971,42.50328086]
               ]
            ]
         }
         ,"properties": {
             "PermanentIdentifier": "14783931"
            ,"ReachCode": "07120004001497"
            ,"GNISName": "Mud Lake"
            ,"AreaSqKm": 0.07798926598
         }
      }
   ]
}
```

## RFC 7946 Changes
The release of [RFC 7946](https://tools.ietf.org/html/rfc7946) in August 2016 removed from GeoJSON the CRS object.  Thus all geometry in GeoJSON is now by definition WGS84 (as in KML).  My release 2.0 removes the previous ability to transform coordinate systems and generate the CRS object.  All incoming geometries are now projected into and rendered as WGS84.  DZ_JSON will avoid reprojection if the incoming SRIDs are already 4326 or 8307.  

The new specification calls for geometries to be partitioned at the antimeridian.  This change [is pending](https://github.com/pauldzy/DZ_JSON/issues/2).

The new specification expressly calls for the removal of any LRS measures.  This is complete.

## Installation
Simply execute the deployment script into the schema of your choice.  Then execute the code using either the same or a different schema.  All procedures and functions are publically executable and utilize AUTHID CURRENT_USER for permissions handling.

## Collaboration
Forks and pulls are **most** welcome.  The deployment script and deployment documentation files in the repository root are generated by my [build system](https://github.com/pauldzy/Speculative_PLSQL_CI) which obviously you do not have.  You can just ignore those files and when I merge your pulls my system will autogenerate updated files for GitHub.

## Oracle Licensing Disclaimer
Oracle places the burden of matching functionality usage with server licensing entirely upon the user.  In the realm of Oracle Spatial, some features are "[spatial](http://download.oracle.com/otndocs/products/spatial/pdf/12c/oraspatitalandgraph_12_fo.pdf)" (and thus a separate purchased "option" beyond enterprise) and some are "[locator](http://download.oracle.com/otndocs/products/spatial/pdf/12c/oraspatialfeatures_12c_fo_locator.pdf)" (bundled with standard and enterprise).  This differentiation is ever changing.  Thus the definition for 11g is not exactly the same as the definition for 12c.  If you are seeking to utilize my code **without** a full Spatial option license, I do provide a good faith estimate of the licensing required and when coding I am conscious of keeping repository functionality to the simplest licensing level when possible.  However - as all such things go - the final burden of determining if functionality in a given repository matches your server licensing is entirely placed upon the user.  You should **always** fully inspect the code and its usage of Oracle functionality in light of your licensing.  Any reliance you place on my estimation is therefore strictly at your own risk.

In my estimation functionality in the DZ_JSON repository should match Oracle Locator licensing for 10g, 11g and 12c.


