CREATE OR REPLACE PACKAGE dz_json_constants
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Constant: dz_json_constants.c_json_unescaped_slashes
      Flag to control whether to escape forward slashes.  Certain libraries may
      or may not require such escaping.
   */
   c_json_unescaped_slashes   CONSTANT BOOLEAN := TRUE;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Constant: dz_json_constants.c_json_unescaped_unicode
      Flag to control escaping of unicode characters into /u format.  Set to TRUE
      to leave all unicode text as received.  Note this is not recommended for
      most JSON handling.
   */
   c_json_unescaped_unicode   CONSTANT BOOLEAN := FALSE;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Constant: dz_json_constants.c_json_escape_all_nonascii
      Flag to control whether to escape all non-ascii characters into /u format.
      May be helpful for certain character sets or use cases.
   */
   c_json_escape_all_nonascii CONSTANT BOOLEAN := FALSE;

END dz_json_constants;
/

GRANT EXECUTE ON dz_json_constants TO PUBLIC;

