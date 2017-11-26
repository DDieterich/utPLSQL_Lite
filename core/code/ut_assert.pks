/* Formatted on 2001/07/13 12:29 (RevealNet Formatter v4.4.1) */
CREATE OR REPLACE PACKAGE utassert
AUTHID CURRENT_USER
IS
   
/************************************************************************
GNU General Public License for utPLSQL

Copyright (C) 2000-2003 
Steven Feuerstein and the utPLSQL Project
(steven@stevenfeuerstein.com)

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see license.txt); if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
************************************************************************
$Log$
Revision 1.2  2003/07/01 19:36:46  chrisrimmer
Added Standard Headers
Revision 3.0  2106/04/04 Duane Dieterich
Converted to v3

************************************************************************/

   test_failure   EXCEPTION;

   TYPE value_name_rt IS RECORD (
      value VARCHAR2(32767),
      name VARCHAR2(100)     );
   TYPE value_name_tt IS
      TABLE OF value_name_rt
      INDEX BY BINARY_INTEGER;

   function version
      return varchar2;

   /* START username:studious Date:01/11/2002 Task_id:42690 */
   /* Modified for v3 Duane Dieterich */
   -- Different than v1, only used with an Assert run outside a Test Suite
   PROCEDURE showresults;
   PROCEDURE noshowresults;
   FUNCTION showing_results RETURN BOOLEAN;
   /* END username:studious Task_id:42690*/

   /* START chrisrimmer 42694 */          
   FUNCTION previous_passed RETURN BOOLEAN;
   FUNCTION previous_failed RETURN BOOLEAN;
   /* END chrisrimmer 42694 */       

   PROCEDURE this (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   BOOLEAN,
      null_ok_in      IN   BOOLEAN := FALSE,
      raise_exc_in    IN   BOOLEAN := FALSE,
      register_in     IN   BOOLEAN := TRUE );

   /*  2.0.8 General evaluation program.  */

   -- VALUE_NAME_TT Overload
   PROCEDURE eval (
      msg_in            IN   VARCHAR2,
      using_in          IN   VARCHAR2,       -- The expression
      value_name_in     IN   value_name_tt,
      null_ok_in        IN   BOOLEAN := FALSE,
      raise_exc_in      IN   BOOLEAN := FALSE );

   -- 2 Name/Values Overload
   PROCEDURE eval (
      msg_in            IN   VARCHAR2,
      using_in          IN   VARCHAR2,       -- The expression
      value1_in         IN   VARCHAR2,
      value2_in         IN   VARCHAR2,
      name1_in          IN   VARCHAR2 := NULL,
      name2_in          IN   VARCHAR2 := NULL,   
      null_ok_in        IN   BOOLEAN := FALSE,
      raise_exc_in      IN   BOOLEAN := FALSE);

   -- String Inputs Overload
   PROCEDURE eq (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      null_ok_in        IN   BOOLEAN := FALSE,
      raise_exc_in      IN   BOOLEAN := FALSE );

   -- Date Inputs Overload
   PROCEDURE eq (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   DATE,
      against_this_in   IN   DATE,
      null_ok_in        IN   BOOLEAN := FALSE,
      raise_exc_in      IN   BOOLEAN := FALSE,
      truncate_in       IN   BOOLEAN := FALSE );

   -- Boolean Inputs Overload
   PROCEDURE eq (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   BOOLEAN,
      against_this_in   IN   BOOLEAN,
      null_ok_in        IN   BOOLEAN := FALSE,
      raise_exc_in      IN   BOOLEAN := FALSE );

   PROCEDURE eqtable (
      msg_in             IN   VARCHAR2,
      check_this_in      IN   VARCHAR2,
      against_this_in    IN   VARCHAR2,
      check_where_in     IN   VARCHAR2 := NULL,
      against_where_in   IN   VARCHAR2 := NULL,
      raise_exc_in       IN   BOOLEAN := FALSE );

   PROCEDURE eqtabcount (
      msg_in             IN   VARCHAR2,
      check_this_in      IN   VARCHAR2,
      against_this_in    IN   VARCHAR2,
      check_where_in     IN   VARCHAR2 := NULL,
      against_where_in   IN   VARCHAR2 := NULL,
      raise_exc_in       IN   BOOLEAN := FALSE );

   PROCEDURE eqquery (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      raise_exc_in      IN   BOOLEAN := FALSE );

   -- Check a query against a single VARCHAR2 value Overload
   PROCEDURE eqqueryvalue (
      msg_in             IN   VARCHAR2,
      check_query_in     IN   VARCHAR2,
      against_value_in   IN   VARCHAR2,
      null_ok_in         IN   BOOLEAN := FALSE,
      raise_exc_in       IN   BOOLEAN := FALSE );

   -- Check a query against a single DATE value Overload
   PROCEDURE eqqueryvalue (
      msg_in             IN   VARCHAR2,
      check_query_in     IN   VARCHAR2,
      against_value_in   IN   DATE,
      null_ok_in         IN   BOOLEAN := FALSE,
      raise_exc_in       IN   BOOLEAN := FALSE );

   -- Check a query against a single NUMBER value Overload
   PROCEDURE eqqueryvalue (
      msg_in             IN   VARCHAR2,
      check_query_in     IN   VARCHAR2,
      against_value_in   IN   NUMBER,
      null_ok_in         IN   BOOLEAN := FALSE,
      raise_exc_in       IN   BOOLEAN := FALSE );

   -- Not currently implemented
   PROCEDURE eqcursor (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      raise_exc_in      IN   BOOLEAN := FALSE );

/* Temporary Commented out for v3, may be moved to another package

   PROCEDURE eqfile (
      msg_in                IN   VARCHAR2,
      check_this_in         IN   VARCHAR2,
      check_this_dir_in     IN   VARCHAR2,
      against_this_in       IN   VARCHAR2,
      against_this_dir_in   IN   VARCHAR2 := NULL,
      raise_exc_in          IN   BOOLEAN := FALSE );
*/

/* Temporary Commented out for v3, may be moved to another package

   -- NO Check Nth Overload
   PROCEDURE eqpipe (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      raise_exc_in      IN   BOOLEAN := FALSE );

   -- Check Nth Overload (Nth is ignored)
   PROCEDURE eqpipe (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      check_nth_in      IN   VARCHAR2 := NULL,
      against_nth_in    IN   VARCHAR2 := NULL,
      raise_exc_in      IN   BOOLEAN := FALSE );
*/

   -- Direct access to collections
   PROCEDURE eqcoll (
      msg_in                IN   VARCHAR2,
      check_this_in         IN   VARCHAR2,            -- pkg1.coll
      against_this_in       IN   VARCHAR2,            -- pkg2.coll
      eqfunc_in             IN   VARCHAR2 := NULL,
      check_startrow_in     IN   PLS_INTEGER := NULL,
      check_endrow_in       IN   PLS_INTEGER := NULL,
      against_startrow_in   IN   PLS_INTEGER := NULL,
      against_endrow_in     IN   PLS_INTEGER := NULL,
      match_rownum_in       IN   BOOLEAN := FALSE,
      null_ok_in            IN   BOOLEAN := TRUE,
      raise_exc_in          IN   BOOLEAN := FALSE );

   -- API based access to collections
   PROCEDURE eqcollapi (
      msg_in                IN   VARCHAR2,
      check_this_pkg_in     IN   VARCHAR2,
      against_this_pkg_in   IN   VARCHAR2,
      eqfunc_in             IN   VARCHAR2 := NULL,
      countfunc_in          IN   VARCHAR2 := 'COUNT',
      firstrowfunc_in       IN   VARCHAR2 := 'FIRST',
      lastrowfunc_in        IN   VARCHAR2 := 'LAST',
      nextrowfunc_in        IN   VARCHAR2 := 'NEXT',
      getvalfunc_in         IN   VARCHAR2 := 'NTHVAL',
      check_startrow_in     IN   PLS_INTEGER := NULL,
      check_endrow_in       IN   PLS_INTEGER := NULL,
      against_startrow_in   IN   PLS_INTEGER := NULL,
      against_endrow_in     IN   PLS_INTEGER := NULL,
      match_rownum_in       IN   BOOLEAN := FALSE,
      null_ok_in            IN   BOOLEAN := TRUE,
      raise_exc_in          IN   BOOLEAN := FALSE );

   -- String Version with Null_OK Overload (Null_OK is ignored)
   PROCEDURE isnotnull (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   VARCHAR2,
      null_ok_in      IN   BOOLEAN := FALSE,
      raise_exc_in    IN   BOOLEAN := FALSE );

   -- Boolean Version with Null_OK Overload (Null_OK is ignored)
   PROCEDURE isnotnull (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   BOOLEAN,
      null_ok_in      IN   BOOLEAN := FALSE,
      raise_exc_in    IN   BOOLEAN := FALSE );

   -- String Version with Null_OK Overload (Null_OK is ignored)
   PROCEDURE isnull (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   VARCHAR2,
      null_ok_in      IN   BOOLEAN := FALSE,
      raise_exc_in    IN   BOOLEAN := FALSE );

   -- Boolean Version with Null_OK Overload (Null_OK is ignored)
   PROCEDURE isnull (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   BOOLEAN,
      null_ok_in      IN   BOOLEAN := FALSE,
      raise_exc_in    IN   BOOLEAN := FALSE );

   -- 1.5.2  (Some 1.5.2 items moved above for clarification)

   --Check a given call throws a named exception Overload
   PROCEDURE raises (
      msg_in           IN   VARCHAR2,
      check_call_in    IN   VARCHAR2,
      against_exc_in   IN   VARCHAR2 );

   --Check a given call throws an exception with a given SQLCODE Overload
   PROCEDURE raises (
      msg_in                VARCHAR2,
      check_call_in    IN   VARCHAR2,
      against_exc_in   IN   NUMBER );

   --Check a given call throws a named exception Overload
   --  Note: This assertion name is "RAISES"
   PROCEDURE throws (
      msg_in           IN   VARCHAR2,
      check_call_in    IN   VARCHAR2,
      against_exc_in   IN   VARCHAR2 );

   --Check a given call throws an exception with a given SQLCODE Overload
   --  Note: This assertion name is "RAISES"
   PROCEDURE throws (
      msg_in                VARCHAR2,
      check_call_in    IN   VARCHAR2,
      against_exc_in   IN   NUMBER );

   -- 2.0.7

/* Temporary Commented out for v3, may be moved to another package

   PROCEDURE fileExists(
      msg_in             IN   VARCHAR2,
      dir_in in varchar2,
      file_in in varchar2,
      null_ok_in         IN   BOOLEAN := FALSE,
      raise_exc_in       IN   BOOLEAN := FALSE );
*/

   /* START username:studious Date:01/11/2002 Task_id:42690 */

   -- Description: Checking object exist
   PROCEDURE objExists (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      null_ok_in        IN   BOOLEAN := FALSE,
      raise_exc_in      IN   BOOLEAN := FALSE );

   PROCEDURE objnotExists (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      null_ok_in        IN   BOOLEAN := FALSE,
      raise_exc_in      IN   BOOLEAN := FALSE );

   /* END username:studious Task_id:42690*/

   /* START chrisrimmer 42696 */

   -- Character Array Version Overload
   PROCEDURE eqoutput (
      msg_in                IN   VARCHAR2,
      check_this_in         IN   DBMS_OUTPUT.CHARARR,                     
      against_this_in       IN   DBMS_OUTPUT.CHARARR,
      ignore_case_in        IN   BOOLEAN := FALSE,
      ignore_whitespace_in  IN   BOOLEAN := FALSE,
      null_ok_in            IN   BOOLEAN := TRUE,
      raise_exc_in          IN   BOOLEAN := FALSE );

   -- String & Delimiter Version Overload
   PROCEDURE eqoutput (
      msg_in                IN   VARCHAR2,
      check_this_in         IN   DBMS_OUTPUT.CHARARR,                     
      against_this_in       IN   VARCHAR2,
      line_delimiter_in     IN   CHAR := NULL,
      ignore_case_in        IN   BOOLEAN := FALSE,
      ignore_whitespace_in  IN   BOOLEAN := FALSE,
      null_ok_in            IN   BOOLEAN := TRUE,
      raise_exc_in          IN   BOOLEAN := FALSE );

   /* END chrisrimmer 42696 */   

   /* START VENKY11 12345 */

/* Temporary Commented out for v3, may be moved to another package

   PROCEDURE eq_refc_table (
      p_msg_nm          IN   VARCHAR2,
      proc_name         IN   VARCHAR2,
      params            IN   utplsql_util.utplsql_params,
      cursor_position   IN   PLS_INTEGER,
      table_name        IN   VARCHAR2 );

   PROCEDURE eq_refc_query (
      p_msg_nm          IN   VARCHAR2,
      proc_name         IN   VARCHAR2,
      params            IN   utplsql_util.utplsql_params,
      cursor_position   IN   PLS_INTEGER,
      qry               IN   VARCHAR2 );
*/

   /* END VENKY11 12345 */
   
END utassert;
/
