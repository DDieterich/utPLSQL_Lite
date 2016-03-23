CREATE OR REPLACE PACKAGE BODY utassert
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
Revision 1.5  2004/11/16 09:46:48  chrisrimmer
Changed to new version detection system.

Revision 1.4  2004/07/14 17:01:57  chrisrimmer
Added first version of pluggable reporter packages

Revision 1.3  2003/07/11 14:32:52  chrisrimmer
Added 'throws' bugfix from Ivan Desjardins

Revision 1.2  2003/07/01 19:36:46  chrisrimmer
Added Standard Headers

Revision 3.0  2106/04/04 Duane Dieterich
Converted to v3

************************************************************************/

   -- Private Constants
   c_not_placeholder   CONSTANT VARCHAR2(10) := '#$NOT$#';

   -- Private Globals
   g_previous_pass   BOOLEAN;          -- chrisrimmer 42694
   g_showresults     BOOLEAN := TRUE;  -- Different than v1, only used with an
                                       --   Assert run outside a Test Suite

   ------------------------------------------------------------
   --
   FUNCTION message_expected (
      expected_in  IN   VARCHAR2,
      and_got_in   IN   VARCHAR2 )
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN 'Expected "'  || expected_in ||
             '" and got "' || and_got_in   ||
             '"';
   END message_expected;

   ------------------------------------------------------------
   --
   FUNCTION message (
      value_in   IN   VARCHAR2,
      premsg_in  IN   VARCHAR2 default '')
      RETURN VARCHAR2
   IS
   BEGIN
      if premsg_in is not null then
         RETURN '"' || premsg_in || '" Result: ' || value_in;
      else
         RETURN 'Result: ' || value_in;
      end if;
   END message;

   ------------------------------------------------------------
   --
   FUNCTION b2v (bool_in IN BOOLEAN)
      RETURN VARCHAR2
   IS
   BEGIN
      IF bool_in        THEN RETURN 'TRUE';
      ELSIF NOT bool_in THEN RETURN 'FALSE';
      ELSE                   RETURN 'NULL';
      END IF;
   END b2v;

   ------------------------------------------------------------
   --
   FUNCTION numfromstr (str IN VARCHAR2)
      RETURN NUMBER
   IS
      sqlstr  VARCHAR2 (1000):= 'begin :val := ' || str || '; end;';
      retval  NUMBER;
   BEGIN
      EXECUTE IMMEDIATE sqlstr USING OUT retval;
      RETURN retval;
   END numfromstr;

   ------------------------------------------------------------
   --
   FUNCTION file_descrip (
      file_in   IN   VARCHAR2,
      dir_in    IN   VARCHAR2 )
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN file_in || '" located in "' || dir_in;
   END file_descrip;

   ------------------------------------------------------------
   --  Local facade for the Report function in utplsql3.
   --   This private procedure is used in v3 instead of the
   --   public "this" procedure in previous versions
   PROCEDURE report (
      assert_name_in     IN   VARCHAR2,
      check_this_in      IN   BOOLEAN,
      msg_in             IN   VARCHAR2,
      assert_details_in  IN   VARCHAR2 := '',
      null_ok_in         IN   BOOLEAN  := FALSE ,
      raise_exc_in       IN   BOOLEAN  := FALSE ,
      register_in        IN   BOOLEAN  := TRUE )
   IS
      l_failure   BOOLEAN :=    NOT check_this_in
                             OR (    check_this_in IS NULL
                                 AND NOT null_ok_in       );
   BEGIN
      -- Report results failure and success
      utplsql.report
         (assert_name_in    => assert_name_in
         ,test_failed_in    => l_failure
         ,message_in        => msg_in
         ,assert_details_in => assert_details_in
         ,register_in       => register_in
         ,showresults_in    => g_showresults);
      g_previous_pass := NOT l_failure;
      IF  raise_exc_in AND l_failure THEN
         RAISE test_failure;
      END IF;
   END report;

   ------------------------------------------------------------
   -- Support success and failure messages
   PROCEDURE this (
      success_msg_in   IN   VARCHAR2,
      failure_msg_in   IN   VARCHAR2,
      check_this_in    IN   BOOLEAN,
      null_ok_in       IN   BOOLEAN := FALSE ,
      raise_exc_in     IN   BOOLEAN := FALSE ,
      register_in      IN   BOOLEAN := TRUE)
   IS
      l_assert_name  VARCHAR2(20) := 'THIS';
      l_msg          VARCHAR2(32767);
   BEGIN
      IF check_this_in THEN l_msg := success_msg_in;
                       ELSE l_msg := failure_msg_in;
      END IF;
      -- Report results
      report (
         assert_name_in     => l_assert_name,
         check_this_in      => check_this_in,
         msg_in             => l_msg,
         assert_details_in  => '',
         null_ok_in         => null_ok_in,
         raise_exc_in       => raise_exc_in,
         register_in        => register_in);
   END this;

   ------------------------------------------------------------
   --
   PROCEDURE ieqminus (
      assert_name_in    IN   VARCHAR2,
      msg_in            IN   VARCHAR2,
      assert_details_in IN   VARCHAR2,
      query1_in         IN   VARCHAR2,
      query2_in         IN   VARCHAR2,
      raise_exc_in      IN   BOOLEAN := FALSE )
   IS
      ival      PLS_INTEGER;
      v_block   VARCHAR2 (32767) := 
'DECLARE
   CURSOR cur IS 
      SELECT 1
       FROM DUAL
       WHERE EXISTS (      (      ( ' || query1_in ||' )
                            MINUS ( ' || query2_in ||' ) )
                     UNION (      ( ' || query2_in ||' )
                            MINUS ( ' || query1_in ||' ) ) );
   rec cur%ROWTYPE;
BEGIN     
   OPEN cur;
   FETCH cur INTO rec;
   IF cur%FOUND THEN 
	    :retval := 1;
   ELSE 
      :retval := 0;
   END IF;
   CLOSE cur;
END;';
      FUNCTION replace_not_placeholder (
         stg_in       IN   VARCHAR2,
         success_in   IN   BOOLEAN)
         RETURN VARCHAR2
      IS
      BEGIN
         IF success_in THEN
            RETURN REPLACE(stg_in, c_not_placeholder, NULL);
         ELSE
            RETURN REPLACE(stg_in, c_not_placeholder, ' not ');
         END IF;
      END replace_not_placeholder;
   BEGIN
      EXECUTE IMMEDIATE v_block USING  OUT ival;
      report (
         assert_name_in    => assert_name_in,
         check_this_in     => ival = 0,
         msg_in            => msg_in,
         assert_details_in => replace_not_placeholder (
                                 stg_in     => assert_details_in,
                                 success_in => ival = 0),
         null_ok_in        => FALSE,
         raise_exc_in      => raise_exc_in);
   EXCEPTION
      WHEN OTHERS THEN
         report (
            assert_name_in    => assert_name_in,
            check_this_in     => SQLCODE = 0,
            msg_in            => msg_in,
            assert_details_in => replace_not_placeholder(
                                    stg_in     => 'SQL Failure: ' || SQLERRM,
                                    success_in => SQLCODE = 0),
            null_ok_in        => FALSE,
            raise_exc_in      => raise_exc_in);
   END ieqminus;

   ------------------------------------------------------------
   --
   PROCEDURE validatecoll (
      check_this_in         IN       VARCHAR2,
      against_this_in       IN       VARCHAR2,
      valid_out             IN OUT   BOOLEAN,
      msg_out               OUT      VARCHAR2,
      countproc_in          IN       VARCHAR2     := 'COUNT',
      firstrowproc_in       IN       VARCHAR2     := 'FIRST',
      lastrowproc_in        IN       VARCHAR2     := 'LAST',
      check_startrow_in     IN       PLS_INTEGER  := NULL,
      check_endrow_in       IN       PLS_INTEGER  := NULL,
      against_startrow_in   IN       PLS_INTEGER  := NULL,
      against_endrow_in     IN       PLS_INTEGER  := NULL,
      match_rownum_in       IN       BOOLEAN      := FALSE ,
      null_ok_in            IN       BOOLEAN      := TRUE ,
      raise_exc_in          IN       BOOLEAN      := FALSE ,
      null_and_valid        IN OUT   BOOLEAN   )
   IS
      dynblock     VARCHAR2 (32767);
      v_matchrow   CHAR (1)   := 'N';
      badc         PLS_INTEGER;
      bada         PLS_INTEGER;
      badtext      VARCHAR2 (32767);
      eqcheck      VARCHAR2 (32767);
   BEGIN
      valid_out := TRUE ;
      null_and_valid := FALSE ;
      IF numfromstr(check_this_in || '.' || countproc_in ) = 0 AND
         numfromstr(against_this_in || '.' || countproc_in ) = 0
      THEN
         IF NOT null_ok_in THEN
            valid_out := FALSE ;
            msg_out := 'Invalid NULL collections';
         ELSE
            /* Empty and valid collections. We are done... */
            null_and_valid := TRUE ;
         END IF;
      END IF;
      IF valid_out AND NOT null_and_valid THEN
         IF match_rownum_in THEN
            valid_out := 
               NVL( numfromstr(check_this_in || '.' || firstrowproc_in) =
                    numfromstr(against_this_in || '.' || firstrowproc_in),
                   FALSE);
            IF NOT valid_out THEN
               msg_out := 'Different starting rows in ' || check_this_in ||
                          ' and ' || against_this_in;
            ELSE
               valid_out :=
                  NVL( numfromstr(check_this_in || '.' || lastrowproc_in) !=
                       numfromstr(against_this_in || '.' || lastrowproc_in),
                      FALSE);
               IF NOT valid_out THEN
                  msg_out := 'Different ending rows in ' || check_this_in ||
                             ' and ' || against_this_in;
               END IF;
            END IF;
         END IF;
         IF valid_out THEN
            valid_out :=
               NVL ( numfromstr(check_this_in || '.' || countproc_in) =
                     numfromstr(against_this_in || '.' || countproc_in),
                    FALSE);
            IF NOT valid_out THEN
               msg_out := 'Different number of rows in ' || check_this_in ||
                          ' and ' || against_this_in;
            END IF;
         END IF;
      END IF;
   END validatecoll;

   ------------------------------------------------------------
   --
   FUNCTION collection_message (
      premsg_in    IN   VARCHAR2,
      chkcoll_in   IN   VARCHAR2,
      chkrow_in    IN   INTEGER,
      agcoll_in    IN   VARCHAR2,
      agrow_in     IN   INTEGER,
      success_in   IN   BOOLEAN )
      RETURN VARCHAR2
   IS
      m1  VARCHAR2(32767);
   BEGIN
      -- Build Message 1
      if success_in then
         m1 := 'Collection "'  || agcoll_in  ||
               '" does match ' || chkcoll_in || '".';
      else
         m1 := 'Row ' || NVL(TO_CHAR(agrow_in),'*UNDEFINED* ') ||
               'of Collection "' || agcoll_in ||
               '" does not match Row ' || NVL(TO_CHAR(chkrow_in),'*UNDEFINED* ') ||
               'of ' || chkcoll_in || '".';
      end if;
      RETURN message(value_in  => m1,
                     premsg_in => premsg_in);
   END collection_message;

   ------------------------------------------------------------
   --
   FUNCTION dyncollstr (
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      eqfunc_in         IN   VARCHAR2,
      countproc_in      IN   VARCHAR2,
      firstrowproc_in   IN   VARCHAR2,
      lastrowproc_in    IN   VARCHAR2,
      nextrowproc_in    IN   VARCHAR2,
      getvalfunc_in     IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      eqcheck     VARCHAR2 (32767);
      v_check     VARCHAR2 (100)   := check_this_in;
      v_against   VARCHAR2 (100)   := against_this_in;
   BEGIN
      IF getvalfunc_in IS NOT NULL THEN
         v_check := v_check || '.' || getvalfunc_in;
         v_against := v_against || '.' || getvalfunc_in;
      END IF;
      IF eqfunc_in IS NULL THEN
         eqcheck := '('||v_check||'(cindx) = '||v_against||' (aindx)) OR '||
                    '('||v_check||'(cindx) IS NULL AND '||v_against||' (aindx) IS NULL)';
      ELSE
         eqcheck := eqfunc_in||'('||v_check||'(cindx),'||v_against||'(aindx))';
      END IF;
      RETURN (
'DECLARE
   cindx PLS_INTEGER;
   aindx PLS_INTEGER;
   cend PLS_INTEGER := NVL(:cendit, '||check_this_in||'.'||lastrowproc_in||');
   aend PLS_INTEGER := NVL(:aendit, '||against_this_in||'.'||lastrowproc_in||');
   different_collections exception;
   PROCEDURE setfailure (
      str IN VARCHAR2,
      badc IN PLS_INTEGER, 
      bada IN PLS_INTEGER, 
      raiseexc IN BOOLEAN := TRUE )
   IS
   BEGIN
      :badcindx := badc;
      :badaindx := bada;
      :badreason := str;
      IF raiseexc THEN RAISE different_collections; END IF;
   END setfailure;
BEGIN
   cindx := NVL(:cstartit, '||check_this_in||'.'||firstrowproc_in||');
   aindx := NVL(:astartit, '||against_this_in||'.'||firstrowproc_in||');
   LOOP
      IF cindx IS NULL AND aindx IS NULL THEN
         EXIT;
      ELSIF cindx IS NULL and aindx IS NOT NULL THEN
         setfailure(''Check index NULL, Against index NOT NULL'', cindx, aindx);
      ELSIF aindx IS NULL THEN   
         setfailure(''Check index NOT NULL, Against index NULL'', cindx, aindx);
      END IF;
      IF :matchit = ''Y'' AND cindx != aindx THEN
         setfailure (''Mismatched row numbers'', cindx, aindx);
      END IF;
      BEGIN
         IF ' || eqcheck || ' THEN
            NULL;
         ELSE
            setfailure(''Mismatched row values'', cindx, aindx);
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            setfailure (''On EQ check: ' || eqcheck || ''' || '' '' || SQLERRM, cindx, aindx);
      END;
      cindx := '||check_this_in||'.'||nextrowproc_in||'(cindx);
      aindx := '||against_this_in||'.'||nextrowproc_in||'(aindx);
   END LOOP;
EXCEPTION
   WHEN OTHERS THEN 
      IF :badcindx IS NULL and :badaindx IS NULL THEN
         setfailure (SQLERRM, cindx, aindx, FALSE);
      END IF;
END;');
   END dyncollstr;

   ------------------------------------------------------------
   --  Description: Checking whether object exists
   FUNCTION find_obj (check_this_in IN VARCHAR2)
      RETURN BOOLEAN
   IS
      v_st         VARCHAR2 (20);
      v_err        VARCHAR2 (100);
      v_schema     VARCHAR2 (100);
      v_obj_name   VARCHAR2 (100);
      v_point      NUMBER           := INSTR (check_this_in, '.');
      v_state      BOOLEAN          := FALSE ;
      v_val        VARCHAR2 (30);
      CURSOR c_obj IS
         SELECT object_name
           FROM all_objects
          WHERE object_name = UPPER (v_obj_name)
            AND owner = UPPER (v_schema);
   BEGIN
      IF v_point = 0 THEN
         v_schema := USER;
         v_obj_name := check_this_in;
      ELSE
         v_schema := SUBSTR(check_this_in, 0, (v_point-1));
         v_obj_name := SUBSTR(check_this_in, (v_point+1));
      END IF;
      OPEN c_obj;
      FETCH c_obj INTO v_val;
      IF c_obj%FOUND THEN
         v_state := TRUE ;
      ELSE
         v_state := FALSE ;
      END IF;
      CLOSE c_obj;
      RETURN v_state;
   EXCEPTION
      WHEN OTHERS THEN
         RETURN FALSE ;
   END find_obj;


------------------------------------------------------------
-----------------------   PUBLIC   -------------------------
------------------------------------------------------------

FUNCTION version
   RETURN varchar2
IS
BEGIN
   return '3.0.1';
END version;


   /* START username:studious Date:01/11/2002 Task_id:42690 */
   PROCEDURE showresults IS BEGIN g_showresults := TRUE ; END;
   PROCEDURE noshowresults IS BEGIN g_showresults := FALSE ; END;
   FUNCTION showing_results RETURN BOOLEAN IS BEGIN RETURN g_showresults; END;
   /* END username:studious Task_id:42690*/

   /* START chrisrimmer 42694 */
   FUNCTION previous_passed RETURN BOOLEAN IS BEGIN RETURN g_previous_pass; END;
   FUNCTION previous_failed RETURN BOOLEAN IS BEGIN RETURN NOT g_previous_pass; END;
   /* END chrisrimmer 42694 */

   ------------------------------------------------------------
   --  Because "this" is a generic Assertion, there are no Assert_Details
   --    sent to the reporter.  All Assert_Details are included in MSG_IN.
   PROCEDURE this (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   BOOLEAN,
      null_ok_in      IN   BOOLEAN := FALSE ,
      raise_exc_in    IN   BOOLEAN := FALSE ,
      register_in     IN   BOOLEAN := TRUE )
   IS
      l_assert_name  VARCHAR2(20) := 'THIS';
   BEGIN
      -- Report results failure and success
      report (
         assert_name_in     => l_assert_name,
         check_this_in      => check_this_in,
         msg_in             => msg_in,
         assert_details_in  => '',
         null_ok_in         => null_ok_in,
         raise_exc_in       => raise_exc_in,
         register_in        => register_in);
   END this;

   -- 2.0.8 General evaluation mechanism 

   ------------------------------------------------------------
   -- VALUE_NAME_TT Overload
   PROCEDURE eval (
      msg_in          IN   VARCHAR2,
      using_in        IN   VARCHAR2, -- The expression   
      value_name_in   IN   value_name_tt,
      null_ok_in      IN   BOOLEAN := FALSE ,
      raise_exc_in    IN   BOOLEAN := FALSE )
   IS
      l_assert_name      VARCHAR2(20) := 'EVAL';
      fdbk               PLS_INTEGER;
      cur                PLS_INTEGER  := DBMS_SQL.open_cursor;
      eval_result        CHAR (1);
      eval_block         varchar2(32767); -- Clear issues of size limitation!
      value_name_str     varchar2(32767);
      eval_description   varchar2(32767);
      parse_error        EXCEPTION;
   BEGIN
      FOR indx IN
          value_name_in.FIRST .. value_name_in.LAST
      LOOP
         value_name_str := value_name_str  || ' ' ||
                           NVL(value_name_in(indx).NAME, 'P'||indx) ||
                           ' = ' || value_name_in (indx).VALUE;
      END LOOP;
      eval_description := 'Evaluation of "' || using_in ||
                          '" with'          || value_name_str;
      eval_block :=
'DECLARE
   b_result BOOLEAN;
BEGIN
   b_result := ' || using_in || ';
   IF b_result THEN
      :result := ''Y'';
   ELSIF NOT b_result THEN
      :result := ''N'';
   ELSE
      :result := NULL;
   END IF;
END;';
      BEGIN
         DBMS_SQL.parse(cur, eval_block, DBMS_SQL.native);
      EXCEPTION
         WHEN OTHERS THEN
            -- Report the parse error!
            IF DBMS_SQL.is_open (cur) THEN
               DBMS_SQL.close_cursor (cur);
            END IF;
               report (
                  assert_name_in    => l_assert_name,
                  check_this_in     => FALSE,
                  msg_in            => msg_in,
                  assert_details_in => 'Error '     || SQLCODE ||
                                       ' parsing '  || eval_block,
                  null_ok_in        => null_ok_in,
                  raise_exc_in      => raise_exc_in);
            RAISE parse_error;
      END;
      FOR indx IN
          value_name_in.FIRST .. value_name_in.LAST
      LOOP
         DBMS_SQL.bind_variable (
            cur,
            NVL(value_name_in(indx).NAME, 'P'||indx),
            value_name_in(indx).VALUE  );
      END LOOP;
      DBMS_SQL.bind_variable (cur, 'result', 'a');
      fdbk := DBMS_SQL.EXECUTE (cur);
      DBMS_SQL.variable_value(cur, 'result', eval_result);
      DBMS_SQL.close_cursor (cur);
      if eval_result = 'Y' then
         report (
            assert_name_in    => l_assert_name,
            check_this_in     => TRUE,
            msg_in            => msg_in,
            assert_details_in => eval_description || ' evaluated to TRUE',
            null_ok_in        => null_ok_in,
            raise_exc_in      => raise_exc_in);
      else
         report (
            assert_name_in    => l_assert_name,
            check_this_in     => FALSE,
            msg_in            => msg_in,
            assert_details_in => eval_description || ' evaluated to FALSE',
            null_ok_in        => null_ok_in,
            raise_exc_in      => raise_exc_in);
      end if;
   EXCEPTION
      WHEN parse_error THEN
         IF raise_exc_in THEN
            RAISE;
         ELSE
            NULL;
         END IF;
      WHEN OTHERS THEN
         IF DBMS_SQL.is_open (cur) THEN
            DBMS_SQL.close_cursor (cur);
         END IF;
         -- Likely the block got too large!
         report (
            assert_name_in    => l_assert_name,
            check_this_in     => FALSE,
            msg_in            => msg_in,
            assert_details_in => 'Error in ' || eval_description || ' SQLERRM: ' || SQLERRM,
            null_ok_in        => null_ok_in,
            raise_exc_in      => raise_exc_in);
   END eval;

   ------------------------------------------------------------
   -- 2 Name/Values Overload
   PROCEDURE eval (
      msg_in            IN  VARCHAR2,
      using_in          IN  VARCHAR2, -- The expression
      value1_in         IN  VARCHAR2,
      value2_in         IN  VARCHAR2,
      name1_in          IN  VARCHAR2 := NULL,
      name2_in          IN  VARCHAR2 := NULL,  
      null_ok_in        IN  BOOLEAN := FALSE,
      raise_exc_in      IN  BOOLEAN := FALSE )
   IS
      value_name   value_name_tt;
   BEGIN
      value_name(1).value := value1_in;
      value_name(1).name := name1_in;
      value_name(2).value := value2_in;
      value_name(2).name := name2_in;
      -- VALUE_NAME_TT Overload
      eval (
         msg_in,
         using_in,
         value_name,
         null_ok_in,
         raise_exc_in );
   END eval;

   ------------------------------------------------------------
   -- String Inputs Overload
   PROCEDURE eq (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      null_ok_in        IN   BOOLEAN := FALSE ,
      raise_exc_in      IN   BOOLEAN := FALSE )
   IS
      l_assert_name      VARCHAR2(20) := 'EQ';
   BEGIN
      report (
         assert_name_in    => l_assert_name,
         check_this_in     =>    NVL(check_this_in = against_this_in, FALSE)
                              OR (    check_this_in IS NULL
                                  AND against_this_in IS NULL
                                  AND null_ok_in              ),
         msg_in            => msg_in,
         assert_details_in => message_expected (
                                 expected_in => against_this_in,
                                 and_got_in  => check_this_in),
         null_ok_in        => FALSE,
         raise_exc_in      => raise_exc_in);
   END eq;

   ------------------------------------------------------------
   -- Date Inputs Overload
   PROCEDURE eq (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   BOOLEAN,
      against_this_in   IN   BOOLEAN,
      null_ok_in        IN   BOOLEAN := FALSE ,
      raise_exc_in      IN   BOOLEAN := FALSE)
   IS
      l_assert_name      VARCHAR2(20) := 'EQ';
   BEGIN
      report (
         assert_name_in    => l_assert_name,
         check_this_in     =>     check_this_in = against_this_in
                               OR (    check_this_in IS NULL
                                   AND against_this_in IS NULL
                                   AND null_ok_in             ),
         msg_in            => msg_in,
         assert_details_in => message_expected (
                                 expected_in => b2v(against_this_in),
                                 and_got_in  => b2v(check_this_in)),
         null_ok_in        => FALSE,
         raise_exc_in      => raise_exc_in);
   END eq;

   ------------------------------------------------------------
   -- Boolean Inputs Overload
   PROCEDURE eq (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   DATE,
      against_this_in   IN   DATE,
      null_ok_in        IN   BOOLEAN := FALSE ,
      raise_exc_in      IN   BOOLEAN := FALSE ,
      truncate_in       IN   BOOLEAN := FALSE )
   IS
      l_assert_name      VARCHAR2(20) := 'EQ';
      c_format  CONSTANT VARCHAR2 (30) := 'MONTH DD, YYYY HH24MISS';
      v_check             VARCHAR2 (100);
      v_against           VARCHAR2 (100);
   BEGIN
      IF truncate_in THEN
         v_check   := TO_CHAR(TRUNC(check_this_in), c_format);
         v_against := TO_CHAR(TRUNC(against_this_in), c_format);
      ELSE
         v_check   := TO_CHAR(check_this_in, c_format);
         v_against := TO_CHAR(against_this_in, c_format);
      END IF;
      report (
         assert_name_in    => l_assert_name,
         check_this_in     =>    v_check = v_against
                              OR (    v_check IS NULL
                                  AND v_against IS NULL
                                  AND null_ok_in            ),
         msg_in            => msg_in,
         assert_details_in => message_expected (
                                 expected_in => v_against,
                                 and_got_in  => v_check ),
         null_ok_in        => FALSE,
         raise_exc_in      => raise_exc_in);
   END eq;

   ------------------------------------------------------------
   --
   PROCEDURE eqtable (
      msg_in             IN   VARCHAR2,
      check_this_in      IN   VARCHAR2,
      against_this_in    IN   VARCHAR2,
      check_where_in     IN   VARCHAR2 := NULL,
      against_where_in   IN   VARCHAR2 := NULL,
      raise_exc_in       IN   BOOLEAN := FALSE )
   IS
      l_assert_name      VARCHAR2(20) := 'EQTABLE';
      CURSOR info_cur (
         sch_in   IN   VARCHAR2,
         tab_in   IN   VARCHAR2)
      IS
         SELECT   t.column_name
             FROM all_tab_columns t
            WHERE t.owner = sch_in
              AND t.table_name = tab_in
         ORDER BY column_id;
      m1  VARCHAR2(32767);
      m2  VARCHAR2(32767);
      m3  VARCHAR2(32767);
      FUNCTION collist (tab IN VARCHAR2)
         RETURN VARCHAR2
      IS
         l_schema   VARCHAR2 (100);
         l_table    VARCHAR2 (100);
         l_dot      PLS_INTEGER := INSTR (tab, '.');
         retval     VARCHAR2 (32767);
      BEGIN
         IF l_dot = 0 THEN
            l_schema := USER;
            l_table := UPPER (tab);
         ELSE
            l_schema := UPPER(SUBSTR(tab,1,l_dot-1));
            l_table  := UPPER(SUBSTR(tab,l_dot+1));
         END IF;
         FOR rec IN info_cur (l_schema, l_table) LOOP
            retval := retval || ',' || rec.column_name;
         END LOOP;
         RETURN LTRIM (retval, ',');
      END collist;
   BEGIN
      -- Build Message 1
      if check_where_in IS NULL then
         m1 := 'Contents of "' || check_this_in ||
                     '" does ' || c_not_placeholder;
      else
         m1 := 'Contents of "' || check_this_in  ||
                    '" WHERE ' || check_where_in ||
                      ' does ' || c_not_placeholder;
      end if;
      if against_where_in IS NULL then
         m1 := m1 || 'match "' || against_this_in || '"';
      else
         m1 := m1 || 'match "' || against_this_in ||
                    '" WHERE ' || against_where_in;
      end if;
      -- Build Message 2 and 3
      m2 := 'SELECT T1.*, COUNT(*)' ||
            ' FROM ' || check_this_in || ' T1' ||
            ' WHERE ' || NVL (check_where_in, '1=1') ||
            ' GROUP BY ' || collist (check_this_in);
      m3 := 'SELECT T2.*, COUNT(*)' ||
            ' FROM ' || against_this_in || ' T2' ||
            ' WHERE ' || NVL (against_where_in, '1=1') ||
            ' GROUP BY ' || collist (against_this_in);
      ieqminus (
         assert_name_in    => l_assert_name,
         msg_in            => msg_in,
         assert_details_in => message(m1),
         query1_in         => m2,
         query2_in         => m3,
         raise_exc_in      => raise_exc_in);
   END eqtable;

   ------------------------------------------------------------
   --
   PROCEDURE eqtabcount (
      msg_in             IN   VARCHAR2,
      check_this_in      IN   VARCHAR2,
      against_this_in    IN   VARCHAR2,
      check_where_in     IN   VARCHAR2 := NULL,
      against_where_in   IN   VARCHAR2 := NULL,
      raise_exc_in       IN   BOOLEAN := FALSE )
   IS
      l_assert_name      VARCHAR2(20) := 'EQTABCOUNT';
      ival   PLS_INTEGER;
      m1  VARCHAR2(32767);
      m2  VARCHAR2(32767);
      m3  VARCHAR2(32767);
   BEGIN
      -- Build Message 1
      if check_where_in IS NULL then
         m1 := 'Row count of "' || check_this_in ||
                      '" does ' || c_not_placeholder;
      else
         m1 := 'Row count of "' || check_this_in  ||
                     '" WHERE ' || check_where_in ||
                       ' does ' || c_not_placeholder;
      end if;
      if against_where_in IS NULL then
         m1 := m1 || 'match that of "' || against_this_in || '"';
      else
         m1 := m1 || 'match that of "' || against_this_in ||
                            '" WHERE ' || against_where_in;
      end if;
      -- Build Message 2 and 3
      m2 := 'SELECT COUNT(*)' ||
            ' FROM ' || check_this_in ||
            ' WHERE ' || NVL (check_where_in, '1=1');
      m3 := 'SELECT COUNT(*)' ||
            ' FROM ' || against_this_in ||
            ' WHERE ' || NVL (against_where_in, '1=1');
      ieqminus (
         assert_name_in    => l_assert_name,
         msg_in            => msg_in,
         assert_details_in => message(m1),
         query1_in         => m2,
         query2_in         => m3,
         raise_exc_in      => raise_exc_in);
   END eqtabcount;

   ------------------------------------------------------------
   --
   PROCEDURE eqquery (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      raise_exc_in      IN   BOOLEAN := FALSE )
   IS
      l_assert_name      VARCHAR2(20) := 'EQQUERY';
      -- User passes in two SELECT statements. Use NDS to minus them.
      ival   PLS_INTEGER;
      m1  VARCHAR2(32767);
   BEGIN
      -- Build Message 1
      m1 := 'Result set for "' || check_this_in     ||
                      ' does ' || c_not_placeholder ||
             'match that of "' || against_this_in   || '"';
      ieqminus (
         assert_name_in    => l_assert_name,
         msg_in            => msg_in,
         assert_details_in => message(m1),
         query1_in         => check_this_in,
         query2_in         => against_this_in,
         raise_exc_in      => raise_exc_in);
   END eqquery;

   ------------------------------------------------------------
   -- Check a query against a single VARCHAR2 value Overload
   PROCEDURE eqqueryvalue (
      msg_in             IN   VARCHAR2,
      check_query_in     IN   VARCHAR2,
      against_value_in   IN   VARCHAR2,
      null_ok_in         IN   BOOLEAN := FALSE ,
      raise_exc_in       IN   BOOLEAN := FALSE )
   IS
      l_assert_name  VARCHAR2(20) := 'EQQUERYVALUE';
      l_value        VARCHAR2 (2000);
      l_success      BOOLEAN;
      TYPE cv_t IS REF CURSOR;
      cv   cv_t;
      m1   VARCHAR2(32767);
   BEGIN
      OPEN cv FOR check_query_in;
      FETCH cv INTO l_value;
      CLOSE cv;
      l_success :=    l_value = against_value_in
                   OR (    l_value IS NULL
                       AND against_value_in IS NULL
                       AND null_ok_in             );
      -- Build Message 1
      m1 := 'Query "' || check_query_in || '" returned value "' ||
                                l_value || '" that does ';
      if l_success then
         m1 := m1 || 'match "' || against_value_in || '"';
      else
         m1 := m1 || 'not match "' || against_value_in || '"';
      end if;
      report (
         assert_name_in    => l_assert_name,
         check_this_in     => l_success,
         msg_in            => msg_in,
         assert_details_in => m1,
         null_ok_in        => FALSE,
         raise_exc_in      => raise_exc_in);
   /* For now ignore this condition.
      How do we handle two assertions inside a single assertion call?
             this (msg_in ||
                ''' || ''; Got multiple values'',
                            check_this_in => FALSE,
                            raise_exc_in => ' ||
                b2v (raise_exc_in) ||
                ');                                                */
   END eqqueryvalue;

   ------------------------------------------------------------
   -- Check a query against a single DATE value Overload
   PROCEDURE eqqueryvalue (
      msg_in             IN   VARCHAR2,
      check_query_in     IN   VARCHAR2,
      against_value_in   IN   DATE,
      null_ok_in         IN   BOOLEAN := FALSE ,
      raise_exc_in       IN   BOOLEAN := FALSE )
   IS
      l_assert_name  VARCHAR2(20) := 'EQQUERYVALUE';
      l_value        DATE;
      l_success      BOOLEAN;
      TYPE cv_t IS REF CURSOR;
      cv   cv_t;
      m1   VARCHAR2(32767);
   BEGIN
      OPEN cv FOR check_query_in;
      FETCH cv INTO l_value;
      CLOSE cv;
      l_success :=    (l_value = against_value_in)
                   OR (    l_value IS NULL
                       AND against_value_in IS NULL
                       AND null_ok_in             );
      -- Build Message 1
      m1 := 'Query "' || check_query_in || '" returned value "' ||
             TO_CHAR(l_value,'DD-MON-YYYY HH24:MI:SS') || '" that does ';
      if l_success then
         m1 := m1 || 'match "';
      else
         m1 := m1 || 'not match "';
      end if;
      m1 := m1 || TO_CHAR(against_value_in, 'DD-MON-YYYY HH24:MI:SS') || '"';
      report (
         assert_name_in    => l_assert_name,
         check_this_in     => l_success,
         msg_in            => msg_in,
         assert_details_in => m1,
         null_ok_in        => FALSE,
         raise_exc_in      => raise_exc_in);
   /* For now ignore this condition.
      How do we handle two assertions inside a single assertion call?
             this (msg_in ||
                ''' || ''; Got multiple values'',
                            check_this_in => FALSE,
                            raise_exc_in => ' ||
                b2v (raise_exc_in) ||
                ');                                               */
   END eqqueryvalue;

   ------------------------------------------------------------
   -- Check a query against a single NUMBER value Overload
   PROCEDURE eqqueryvalue (
      msg_in             IN   VARCHAR2,
      check_query_in     IN   VARCHAR2,
      against_value_in   IN   NUMBER,
      null_ok_in         IN   BOOLEAN := FALSE ,
      raise_exc_in       IN   BOOLEAN := FALSE )
   IS
      l_assert_name  VARCHAR2(20) := 'EQQUERYVALUE';
      l_value        NUMBER;
      l_success      BOOLEAN;
      TYPE cv_t IS REF CURSOR;
      cv   cv_t;
      m1   VARCHAR2(32767);
   BEGIN
      OPEN cv FOR check_query_in;
      FETCH cv INTO l_value;
      CLOSE cv;
      l_success :=    (l_value = against_value_in)
                   OR (    l_value IS NULL
                       AND against_value_in IS NULL
                       AND null_ok_in            );
      -- Build Message 1
      m1 := 'Query "' || check_query_in || '" returned value "' ||
                                l_value || '" that does ';
      if l_success then
         m1 := m1 || 'match "' || against_value_in || '"';
      else
         m1 := m1 || 'not match "' || against_value_in || '"';
      end if;
      report (
         assert_name_in    => l_assert_name,
         check_this_in     => l_success,
         msg_in            => msg_in,
         assert_details_in => m1,
         null_ok_in        => FALSE,
         raise_exc_in      => raise_exc_in);
   /* For now ignore this condition.
      How do we handle two assertions inside a single assertion call?
             this (msg_in ||
                ''' || ''; Got multiple values'',
                            check_this_in => FALSE,
                            raise_exc_in => ' ||
                b2v (raise_exc_in) ||
                ');                                                */
   END eqqueryvalue;

   ------------------------------------------------------------
   -- Not currently implemented
   PROCEDURE eqcursor (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      raise_exc_in      IN   BOOLEAN := FALSE )
   -- User passes in names of two packaged cursors.
   -- Have to loop through each row and compare!
   -- How do I compare the contents of two records
   -- which have been defined dynamically?
   IS
      l_assert_name  VARCHAR2(20) := 'EQCURSOR';
   BEGIN
      utplsql.report
         (assert_name_in    => l_assert_name
         ,test_failed_in    => TRUE
         ,message_in        => 'Not currently implemented'
         ,assert_details_in => 'Not currently implemented'
         ,errors_in         => 'Not currently implemented'
         ,showresults_in    => g_showresults);
   END eqcursor;

/* Temporary Commented out for v3, may be moved to another package

   ------------------------------------------------------------
   --
   PROCEDURE eqfile (
      msg_in                IN   VARCHAR2,
      check_this_in         IN   VARCHAR2,
      check_this_dir_in     IN   VARCHAR2,
      against_this_in       IN   VARCHAR2,
      against_this_dir_in   IN   VARCHAR2 := NULL,
      raise_exc_in          IN   BOOLEAN := FALSE )
   IS
      checkid                  UTL_FILE.file_type;
      againstid                UTL_FILE.file_type;
      samefiles                BOOLEAN          := TRUE ;
      checkline                VARCHAR2 (32767);
      diffline                 VARCHAR2 (32767);
      againstline              VARCHAR2 (32767);
      check_eof                BOOLEAN;
      against_eof              BOOLEAN;
      diffline_set             BOOLEAN;
      nth_line                 PLS_INTEGER        := 1;
      cant_open_check_file     EXCEPTION;
      cant_open_against_file   EXCEPTION;

      PROCEDURE cleanup (
         val           IN   BOOLEAN,
         line_in       IN   VARCHAR2 := NULL,
         line_set_in   IN   BOOLEAN := FALSE ,
         linenum_in    IN   PLS_INTEGER := NULL,
         msg_in        IN   VARCHAR2       )
      IS
         m1  VARCHAR2(32767);
      BEGIN
         UTL_FILE.fclose (checkid);
         UTL_FILE.fclose (againstid);
         -- Build Message 1
         m1 := ifelse(line_set_in,
                      ' Line ' || linenum_in || ' of ',
                      NULL                             ) ||
               'File "' || file_descrip(check_this_in, check_this_dir_in) ||
               '" does ' || ifelse(val, NULL, ' not ') ||
               'match "' || file_descrip(against_this_in, against_this_dir_in) || '".';
         this (
            message(m1),
            val,
            FALSE ,
            raise_exc_in,
            TRUE         );
      END cleanup;
   BEGIN
      -- Compare contents of two files.
      BEGIN
         checkid := UTL_FILE.fopen(check_this_dir_in,
                                   check_this_in,
                                   'R',
                                   max_linesize => 32767 );
      EXCEPTION
         WHEN OTHERS THEN
            RAISE cant_open_check_file;
      END;
      BEGIN
         againstid := UTL_FILE.fopen(NVL(against_this_dir_in, check_this_dir_in),
                                     against_this_in,
                                     'R',
                                     max_linesize => 32767  );
      EXCEPTION
         WHEN OTHERS THEN
            RAISE cant_open_against_file;
      END;
      LOOP
         BEGIN
            UTL_FILE.get_line(checkid, checkline);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               check_eof := TRUE ;
         END;
         BEGIN
            UTL_FILE.get_line(againstid, againstline);
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               against_eof := TRUE ;
         END;
         IF check_eof AND against_eof THEN
            samefiles := TRUE ;
            EXIT;
         ELSIF checkline != againstline THEN
            diffline := checkline;
            diffline_set := TRUE ;
            samefiles := FALSE ;
            EXIT;
         ELSIF check_eof OR against_eof THEN
            samefiles := FALSE ;
            EXIT;
         END IF;
         IF samefiles THEN
            nth_line := nth_line + 1;
         END IF;
      END LOOP;
      cleanup (
         samefiles,
         diffline,
         diffline_set,
         nth_line,
         msg_in
      );
   EXCEPTION
      WHEN cant_open_check_file THEN
         cleanup(
            FALSE ,
            msg_in=> 'Unable to open ' ||
                     file_descrip (check_this_in, check_this_dir_in));
      WHEN cant_open_against_file THEN
         cleanup (
            FALSE ,
            msg_in=> 'Unable to open ' ||
                     file_descrip(against_this_in, NVL(against_this_dir_in, check_this_dir_in)));
      WHEN OTHERS THEN
         cleanup (FALSE, msg_in => msg_in);
   END eqfile;
*/

/* Temporary Commented out for v3, may be moved to another package

   ------------------------------------------------------------
   -- NO Check Nth Overload
   PROCEDURE eqpipe (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      raise_exc_in      IN   BOOLEAN := FALSE )
   IS
      check_tab        utpipe3.msg_tbltype;
      against_tab      utpipe3.msg_tbltype;
      check_status     PLS_INTEGER;
      against_status   PLS_INTEGER;
      same_message     BOOLEAN     := FALSE ;
      msgset           BOOLEAN;
      msgnum           PLS_INTEGER;
      nthmsg           PLS_INTEGER := 1;
      m1  VARCHAR2(32767);
      PROCEDURE compare_pipe_tabs (
         tab1                utpipe3.msg_tbltype,
         tab2                utpipe3.msg_tbltype,
         same_out   IN OUT   BOOLEAN   )
      IS
         indx   PLS_INTEGER := tab1.FIRST;
      BEGIN
         LOOP
            EXIT WHEN indx IS NULL;
            BEGIN
               IF tab1(indx).item_type = 9 THEN
                  same_out := tab1(indx).mvc2 = tab2(indx).mvc2;
               ELSIF tab1(indx).item_type = 6 THEN
                  same_out := tab1(indx).mnum = tab2(indx).mnum;
               ELSIF tab1(indx).item_type = 12 THEN
                  same_out := tab1(indx).mdt = tab2(indx).mdt;
               ELSIF tab1(indx).item_type = 11 THEN
                  same_out := tab1(indx).mrid = tab2(indx).mrid;
               ELSIF tab1(indx).item_type = 23 THEN
                  same_out := tab1(indx).mraw = tab2(indx).mraw;
               END IF;
            EXCEPTION
               WHEN OTHERS THEN
                  same_out := FALSE ;
            END;
            EXIT WHEN NOT same_out;
            indx := tab1.NEXT(indx);
         END LOOP;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            same_out := FALSE ;
      END compare_pipe_tabs;
   BEGIN
      -- Compare contents of two pipes.
      LOOP
         utpipe3.receive_and_unpack (
            check_this_in,
            check_tab,
            check_status  );
         utpipe3.receive_and_unpack (
            against_this_in,
            against_tab,
            against_status  );
         IF check_status = 0 AND against_status = 0 THEN
            compare_pipe_tabs (
               check_tab,
               against_tab,
               same_message );
            IF NOT same_message THEN
               msgset := TRUE ;
               msgnum := nthmsg;
               EXIT;
            END IF;
            EXIT WHEN NOT same_message;
         ELSIF check_status = 1 AND against_status = 1 THEN -- time out
            same_message := TRUE ;
            EXIT;
         ELSE
            same_message := FALSE ;
            EXIT;
         END IF;
         nthmsg := nthmsg + 1;
      END LOOP;
      -- Build Message 1
      m1 := ifelse(msgset, ' Message '||msgnum||' of ', NULL) ||
            'Pipe "' || check_this_in ||
            '" does ' || ifelse(same_message, NULL, ' not ') ||
            'match "' || against_this_in || '".';
      this (
         message(m1),
         same_message,
         FALSE ,
         raise_exc_in,
         TRUE );
   END eqpipe;

   ------------------------------------------------------------
   -- Check Nth Overload (Nth is ignored)
   PROCEDURE eqpipe (
      msg_in            IN   VARCHAR2,
      check_this_in     IN   VARCHAR2,
      against_this_in   IN   VARCHAR2,
      check_nth_in      IN   VARCHAR2 := NULL,
      against_nth_in    IN   VARCHAR2 := NULL,
      raise_exc_in      IN   BOOLEAN := FALSE )
   IS
   BEGIN
      -- NO Check Nth Overload  ?? This is v2 Functionality ??
      eqpipe (
         msg_in,
         check_this_in,
         against_this_in,
         raise_exc_in    );
   END eqpipe;
*/

   ------------------------------------------------------------
   -- Direct access to collections
   PROCEDURE eqcoll (
      msg_in                IN   VARCHAR2,
      check_this_in         IN   VARCHAR2,
      against_this_in       IN   VARCHAR2,
      eqfunc_in             IN   VARCHAR2     := NULL,
      check_startrow_in     IN   PLS_INTEGER  := NULL,
      check_endrow_in       IN   PLS_INTEGER  := NULL,
      against_startrow_in   IN   PLS_INTEGER  := NULL,
      against_endrow_in     IN   PLS_INTEGER  := NULL,
      match_rownum_in       IN   BOOLEAN      := FALSE ,
      null_ok_in            IN   BOOLEAN      := TRUE ,
      raise_exc_in          IN   BOOLEAN      := FALSE )
   IS
      l_assert_name         VARCHAR2(20) := 'EQCOLL';
      dynblock              VARCHAR2 (32767);
      v_matchrow            CHAR (1)         := 'N';
      valid_interim         BOOLEAN;
      invalid_interim_msg   VARCHAR2 (4000);
      badc                  PLS_INTEGER;
      bada                  PLS_INTEGER;
      badtext               VARCHAR2 (32767);
      null_and_valid        BOOLEAN          := FALSE ;
   BEGIN
      validatecoll (
         check_this_in        =>  check_this_in,
         against_this_in      =>  against_this_in,
         valid_out            =>  valid_interim,
         msg_out              =>  invalid_interim_msg,
         countproc_in         =>  'COUNT',
         firstrowproc_in      =>  'FIRST',
         lastrowproc_in       =>  'LAST',
         check_startrow_in    =>  check_startrow_in,
         check_endrow_in      =>  check_endrow_in,
         against_startrow_in  =>  against_startrow_in,
         against_endrow_in    =>  against_endrow_in,
         match_rownum_in      =>  match_rownum_in,
         null_ok_in           =>  null_ok_in,
         raise_exc_in         =>  raise_exc_in,
         null_and_valid       =>  null_and_valid);
      IF NOT valid_interim THEN
         -- Failure on interim step. Flag and skip rest of processing
         report (
            assert_name_in    => l_assert_name,
            check_this_in     => FALSE,
            msg_in            => msg_in,
            assert_details_in => collection_message (
                                    premsg_in    => invalid_interim_msg,
                                    chkcoll_in   => check_this_in,
                                    chkrow_in    => NULL,
                                    agcoll_in    => against_this_in,
                                    agrow_in     => NULL,
                                    success_in   => FALSE),
            null_ok_in        => FALSE,
            raise_exc_in      => raise_exc_in);
      ELSE
         -- We have some data to compare.
         IF NOT null_and_valid THEN
            IF match_rownum_in THEN
               v_matchrow := 'Y';
            END IF;
            dynblock :=
               dyncollstr (
                  check_this_in    => check_this_in,
                  against_this_in  => against_this_in,
                  eqfunc_in        => eqfunc_in,
                  countproc_in     => 'COUNT',
                  firstrowproc_in  => 'FIRST',
                  lastrowproc_in   => 'LAST',
                  nextrowproc_in   => 'NEXT',
                  getvalfunc_in    => NULL );
            EXECUTE IMMEDIATE dynblock
               USING  IN      check_endrow_in,
                      IN      against_endrow_in,
                      IN  OUT badc,
                      IN  OUT bada,
                      IN  OUT badtext,
                      IN      check_startrow_in,
                      IN      against_startrow_in,
                      IN      v_matchrow;
         END IF;
         report (
            assert_name_in    => l_assert_name,
            check_this_in     => badc IS NULL AND bada IS NULL,
            msg_in            => msg_in,
            assert_details_in => collection_message (
                                    premsg_in    => '',
                                    chkcoll_in   => check_this_in,
                                    chkrow_in    => badc,
                                    agcoll_in    => against_this_in,
                                    agrow_in     => bada,
                                    success_in   => badc IS NULL AND bada IS NULL),
            null_ok_in        => FALSE,
            raise_exc_in      => raise_exc_in);
      END IF;
   EXCEPTION
      WHEN OTHERS THEN --p.l (sqlerrm);
         report (
            assert_name_in    => l_assert_name,
            check_this_in     => SQLCODE = 0,
            msg_in            => msg_in,
            assert_details_in => collection_message (
                                    premsg_in    => '',
                                    chkcoll_in   => check_this_in,
                                    chkrow_in    => badc,
                                    agcoll_in    => against_this_in,
                                    agrow_in     => bada,
                                    success_in   => badc IS NULL AND bada IS NULL),
            null_ok_in        => FALSE,
            raise_exc_in      => raise_exc_in);
   END eqcoll;

   ------------------------------------------------------------
   -- API based access to collections
   PROCEDURE eqcollapi (
      msg_in                IN   VARCHAR2,
      check_this_pkg_in     IN   VARCHAR2,
      against_this_pkg_in   IN   VARCHAR2,
      eqfunc_in             IN   VARCHAR2     := NULL,
      countfunc_in          IN   VARCHAR2     := 'COUNT',
      firstrowfunc_in       IN   VARCHAR2     := 'FIRST',
      lastrowfunc_in        IN   VARCHAR2     := 'LAST',
      nextrowfunc_in        IN   VARCHAR2     := 'NEXT',
      getvalfunc_in         IN   VARCHAR2     := 'NTHVAL',
      check_startrow_in     IN   PLS_INTEGER  := NULL,
      check_endrow_in       IN   PLS_INTEGER  := NULL,
      against_startrow_in   IN   PLS_INTEGER  := NULL,
      against_endrow_in     IN   PLS_INTEGER  := NULL,
      match_rownum_in       IN   BOOLEAN      := FALSE ,
      null_ok_in            IN   BOOLEAN      := TRUE ,
      raise_exc_in          IN   BOOLEAN      := FALSE )
   IS
      l_assert_name         VARCHAR2(20) := 'EQCOLLAPI';
      dynblock              VARCHAR2 (32767);
      v_matchrow            CHAR (1)         := 'N';
      badc                  PLS_INTEGER;
      bada                  PLS_INTEGER;
      badtext               VARCHAR2 (32767);
      valid_interim         BOOLEAN;
      invalid_interim_msg   VARCHAR2 (4000);
      null_and_valid        BOOLEAN          := FALSE ;
   BEGIN
      validatecoll (
         check_this_in        =>  check_this_pkg_in,
         against_this_in      =>  against_this_pkg_in,
         valid_out            =>  valid_interim,
         msg_out              =>  invalid_interim_msg,
         countproc_in         =>  countfunc_in,
         firstrowproc_in      =>  firstrowfunc_in,
         lastrowproc_in       =>  lastrowfunc_in,
         check_startrow_in    =>  check_startrow_in,
         check_endrow_in      =>  check_endrow_in,
         against_startrow_in  =>  against_startrow_in,
         against_endrow_in    =>  against_endrow_in,
         match_rownum_in      =>  match_rownum_in,
         null_ok_in           =>  null_ok_in,
         raise_exc_in         =>  raise_exc_in,
         null_and_valid       =>  null_and_valid);
      IF null_and_valid THEN
         GOTO normal_termination;
      END IF;
      IF match_rownum_in THEN
         v_matchrow := 'Y';
      END IF;
      dynblock := dyncollstr (
                     check_this_in    => check_this_pkg_in,
                     against_this_in  => against_this_pkg_in,
                     eqfunc_in        => eqfunc_in,
                     countproc_in     => countfunc_in,
                     firstrowproc_in  => firstrowfunc_in,
                     lastrowproc_in   => lastrowfunc_in,
                     nextrowproc_in   => nextrowfunc_in,
                     getvalfunc_in    => getvalfunc_in );
      EXECUTE IMMEDIATE dynblock
         USING  IN check_endrow_in,
          IN    against_endrow_in,
          IN  OUT badc,
          IN  OUT bada,
          IN  OUT badtext,
          IN    check_startrow_in,
          IN    against_startrow_in,
          IN    v_matchrow;
      <<normal_termination>>
      report (
         assert_name_in    => l_assert_name,
         check_this_in     => bada IS NULL AND badc IS NULL,
         msg_in            => msg_in,
         assert_details_in => collection_message (
                                 premsg_in    => '',
                                 chkcoll_in   => check_this_pkg_in,
                                 chkrow_in    => badc,
                                 agcoll_in    => against_this_pkg_in,
                                 agrow_in     => bada,
                                 success_in   => badc IS NULL AND bada IS NULL),
         null_ok_in        => FALSE,
         raise_exc_in      => raise_exc_in);
   EXCEPTION
      WHEN OTHERS THEN --p.l (sqlerrm);
         report (
            assert_name_in    => l_assert_name,
            check_this_in     => SQLCODE = 0,
            msg_in            => msg_in,
            assert_details_in => collection_message (
                                    premsg_in    => 'SQLERROR: ' || SQLERRM,
                                    chkcoll_in   => check_this_pkg_in,
                                    chkrow_in    => badc,
                                    agcoll_in    => against_this_pkg_in,
                                    agrow_in     => bada,
                                    success_in   => badc IS NULL AND bada IS NULL),
            null_ok_in        => FALSE,
            raise_exc_in      => raise_exc_in);
   END eqcollapi;

   ------------------------------------------------------------
   -- String Version with Null_OK Overload (Null_OK is ignored)
   PROCEDURE isnotnull (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   VARCHAR2,
      null_ok_in      IN   BOOLEAN := FALSE,
      raise_exc_in    IN   BOOLEAN := FALSE)
   IS
      l_assert_name  VARCHAR2(20) := 'ISNOTNULL';
   BEGIN
      report (
         assert_name_in     => l_assert_name,
         check_this_in      => check_this_in IS NOT NULL,
         msg_in             => msg_in,
         assert_details_in  => message_expected (
                                  expected_in => 'NOT NULL',
                                  and_got_in  => check_this_in ),
         null_ok_in         => FALSE,
         raise_exc_in       => raise_exc_in);
   END isnotnull;

   ------------------------------------------------------------
   -- String Version with Null_OK Overload (Null_OK is ignored)
   PROCEDURE isnull (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   VARCHAR2,
      null_ok_in      IN   BOOLEAN := FALSE,
      raise_exc_in    IN   BOOLEAN := FALSE)
   IS
      l_assert_name  VARCHAR2(20) := 'ISNULL';
   BEGIN
      report (
         assert_name_in     => l_assert_name,
         check_this_in      => check_this_in IS NULL,
         msg_in             => msg_in,
         assert_details_in  => message_expected (
                                  expected_in => '',
                                  and_got_in  => check_this_in ),
         null_ok_in         => TRUE,
         raise_exc_in       => raise_exc_in);
   END isnull;

   -- 1.5.2

   ------------------------------------------------------------
   -- Boolean Version with Null_OK Overload (Null_OK is ignored)
   PROCEDURE isnotnull (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   BOOLEAN,
      null_ok_in      IN   BOOLEAN := FALSE,
      raise_exc_in    IN   BOOLEAN := FALSE)
   IS
      l_assert_name  VARCHAR2(20) := 'ISNOTNULL';
   BEGIN
      report (
         assert_name_in     => l_assert_name,
         check_this_in      => check_this_in IS NOT NULL,
         msg_in             => msg_in,
         assert_details_in  => message_expected (
                                  expected_in => 'NOT NULL',
                                  and_got_in  => b2v(check_this_in) ),
         null_ok_in         => FALSE,
         raise_exc_in       => raise_exc_in);
   END isnotnull;

   ------------------------------------------------------------
   -- Boolean Version with Null_OK Overload (Null_OK is ignored)
   PROCEDURE isnull (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   BOOLEAN,
      null_ok_in      IN   BOOLEAN := FALSE,
      raise_exc_in    IN   BOOLEAN := FALSE)
   IS
      l_assert_name  VARCHAR2(20) := 'ISNULL';
   BEGIN
      report (
         assert_name_in     => l_assert_name,
         check_this_in      => check_this_in IS NULL,
         msg_in             => msg_in,
         assert_details_in  => message_expected (
                                  expected_in => '',
                                  and_got_in  => b2v(check_this_in) ),
         null_ok_in         => TRUE,
         raise_exc_in       => raise_exc_in);
   END isnull;

   ------------------------------------------------------------
   -- Check a given call throws a named exception Overload
   PROCEDURE raises (
      msg_in                VARCHAR2,
      check_call_in    IN   VARCHAR2,
      against_exc_in   IN   VARCHAR2 )
   IS
      l_assert_name        VARCHAR2(20)     := 'RAISES';
      expected_indicator   PLS_INTEGER      := 1000;
      l_indicator          PLS_INTEGER;
      v_block              VARCHAR2 (32767) :=
'BEGIN
   ' || RTRIM (RTRIM (check_call_in), ';') || ';
   :indicator := 0;
EXCEPTION
   WHEN ' || against_exc_in || ' THEN
      :indicator := ' || expected_indicator || ';
   WHEN OTHERS THEN :indicator := SQLCODE;
END;';
      m1  VARCHAR2(32767);
   BEGIN
      --Fire off the dynamic PL/SQL
      EXECUTE IMMEDIATE v_block USING  OUT l_indicator;
      -- Build Message 1
      if NOT NVL(l_indicator = expected_indicator, FALSE) then
         m1 := 'Block "' || check_call_in ||
               '" does not raise Exception "' || against_exc_in;
      else
         m1 := 'Block "' || check_call_in ||
               '" raises Exception "' || against_exc_in;
      end if;
      if l_indicator = expected_indicator then
         m1 := m1 || '';
      else
         m1 := m1 || '. Instead it raises SQLCODE = ' || l_indicator || '.';
      end if;
      report (
         assert_name_in    => l_assert_name,
         check_this_in     => l_indicator = expected_indicator,
         msg_in            => msg_in,
         assert_details_in => message(m1),
         null_ok_in        => FALSE);
   END raises;

   ------------------------------------------------------------
   --Check a given call throws an exception with a given SQLCODE Overload
   PROCEDURE raises (
      msg_in                VARCHAR2,
      check_call_in    IN   VARCHAR2,
      against_exc_in   IN   NUMBER  )
   IS
      l_assert_name        VARCHAR2(20)     := 'RAISES';
      expected_indicator   PLS_INTEGER      := 1000;
      l_indicator          PLS_INTEGER;
      v_block              VARCHAR2 (32767) :=
'BEGIN
   ' || RTRIM (RTRIM (check_call_in), ';') || ';
   :indicator := 0;
EXCEPTION
   WHEN OTHERS THEN
      IF SQLCODE = ' || against_exc_in || ' THEN
         :indicator := ' || expected_indicator || ';
      ELSE
         :indicator := SQLCODE;
      END IF;
END;';
      m1  VARCHAR2(32767);
   BEGIN
      --Fire off the dynamic PL/SQL
      EXECUTE IMMEDIATE v_block USING  OUT l_indicator;
      -- Build Message 1
      if NOT NVL(l_indicator = expected_indicator, FALSE) then
         m1 := 'Block "' || check_call_in ||
               '" does not raise Exception "' || against_exc_in;
      else
         m1 := 'Block "' || check_call_in ||
               '" raises Exception "' || against_exc_in;
      end if;
      if l_indicator = expected_indicator then
         m1 := m1 || '';
      else
         m1 := m1 || '. Instead it raises SQLCODE = ' || l_indicator || '.';
      end if;
      report (
         assert_name_in    => l_assert_name,
         check_this_in     => l_indicator = expected_indicator,
         msg_in            => msg_in,
         assert_details_in => message(m1),
         null_ok_in        => FALSE);
   END raises;

   ------------------------------------------------------------
   -- Check a given call throws a named exception Overload
   PROCEDURE throws (
      msg_in                VARCHAR2,
      check_call_in    IN   VARCHAR2,
      against_exc_in   IN   VARCHAR2 )
   IS
   BEGIN
      raises (
         msg_in,
         check_call_in,
         against_exc_in );
   END throws;

   ------------------------------------------------------------
   -- Check a given call throws an exception with a given SQLCODE Overload
   PROCEDURE throws (
      msg_in                VARCHAR2,
      check_call_in    IN   VARCHAR2,
      against_exc_in   IN   NUMBER )
   IS
   BEGIN
      raises (
         msg_in,
         check_call_in,
         against_exc_in );
   END throws;

   -- 2.0.7

/* Temporary Commented out for v3, may be moved to another package

   ------------------------------------------------------------
   --
   PROCEDURE fileexists (
      msg_in         IN   VARCHAR2,
      dir_in         IN   VARCHAR2,
      file_in        IN   VARCHAR2,
      null_ok_in     IN   BOOLEAN := FALSE ,
      raise_exc_in   IN   BOOLEAN := FALSE )
   IS
      checkid   UTL_FILE.file_type;
      PROCEDURE cleanup (
         val      IN   BOOLEAN,
         msg_in   IN   VARCHAR2)
      IS
         m1  VARCHAR2(32767);
      BEGIN
         UTL_FILE.fclose (checkid);
         -- Build Message 1
         m1 := 'File "' || file_descrip (file_in, dir_in) ||
               '" could ' || ifelse(val, NULL, ' not ') ||
               'be opened for reading."';
         this (
            message(m1),
            val,
            FALSE ,
            raise_exc_in,
            TRUE );
      END cleanup;
   BEGIN
      checkid :=
         UTL_FILE.fopen (
            dir_in,
            file_in,
            'R',
            max_linesize => 32767 );
      cleanup (TRUE , msg_in);
   EXCEPTION
      WHEN OTHERS THEN
         cleanup (FALSE , msg_in);
   END fileexists;
*/

   /* START username:studious Date:01/11/2002 Task_id:42690 */

   ------------------------------------------------------------
   --
   PROCEDURE objexists (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   VARCHAR2,
      null_ok_in      IN   BOOLEAN := FALSE ,
      raise_exc_in    IN   BOOLEAN := FALSE )
   IS
   BEGIN
      this (
         message(value_in   => 'This object Exists',
                 premsg_in  => check_this_in),
         message(value_in   => 'This object does not Exist',
                 premsg_in  => check_this_in),
         find_obj (check_this_in),
         null_ok_in,
         raise_exc_in,
         TRUE );
   END objexists;

   ------------------------------------------------------------
   --
   PROCEDURE objnotexists (
      msg_in          IN   VARCHAR2,
      check_this_in   IN   VARCHAR2,
      null_ok_in      IN   BOOLEAN := FALSE ,
      raise_exc_in    IN   BOOLEAN := FALSE )
   IS
   BEGIN
      this (
         message(value_in   => 'This object does not Exist',
                 premsg_in  => check_this_in),
         message(value_in   => 'This object Exists',
                 premsg_in  => check_this_in),
         NOT find_obj(check_this_in),
         null_ok_in,
         raise_exc_in,
         TRUE );
   END objnotexists;

   /* END username:studious Task_id:42690*/

   /* START chrisrimmer 42696 */

   ------------------------------------------------------------
   -- Character Array Version Overload
   PROCEDURE eqoutput (
      msg_in                IN   VARCHAR2,
      check_this_in         IN   DBMS_OUTPUT.CHARARR,                     
      against_this_in       IN   DBMS_OUTPUT.CHARARR,
      ignore_case_in        IN   BOOLEAN := FALSE,
      ignore_whitespace_in  IN   BOOLEAN := FALSE,
      null_ok_in            IN   BOOLEAN := TRUE,
      raise_exc_in          IN   BOOLEAN := FALSE )
   IS
      l_assert_name      VARCHAR2(20) := 'EQOUTPUT';
      WHITESPACE   CONSTANT CHAR(5) := '!'||CHR(9)||CHR(10)||CHR(13)||CHR(32);
      NOWHITESPACE CONSTANT CHAR(1) := '!';
      v_check_index     BINARY_INTEGER;
      v_against_index   BINARY_INTEGER;
      v_message         VARCHAR2(1000);
      v_line1           VARCHAR2(1000);      
      v_line2           VARCHAR2(1000);
      FUNCTION Preview_Line (line_in VARCHAR2) 
         RETURN VARCHAR2
      IS
      BEGIN
        IF LENGTH(line_in) <= 100 THEN
          RETURN line_in;
        ELSE
          RETURN SUBSTR(line_in, 1, 97) || '...';
        END IF;
      END Preview_Line;
   BEGIN
      v_check_index := check_this_in.FIRST;
      v_against_index := against_this_in.FIRST;
      WHILE v_check_index IS NOT NULL AND
            v_against_index IS NOT NULL AND
            v_message IS NULL
      LOOP
         v_line1 := check_this_in(v_check_index);
         v_line2 := against_this_in(v_against_index);
         IF ignore_case_in THEN
           v_line1 := UPPER(v_line1);
           v_line2 := UPPER(v_line2);
         END IF;
         IF ignore_whitespace_in THEN
           v_line1 := TRANSLATE(v_line1, WHITESPACE, NOWHITESPACE);
           v_line2 := TRANSLATE(v_line2, WHITESPACE, NOWHITESPACE);
         END IF;
         IF (NVL (v_line1 <> v_line2, NOT null_ok_in)) THEN
           v_message := message_expected (
                           expected_in => Preview_Line(check_this_in(v_check_index)),
                           and_got_in  => Preview_Line(against_this_in(v_against_index)) ) ||
               ' (Comparing line ' || v_check_index || 
               ' of tested collection against line ' || v_against_index ||
               ' of reference collection)';
         END IF;
         v_check_index := check_this_in.NEXT(v_check_index);
         v_against_index := against_this_in.NEXT(v_against_index);
      END LOOP;
      IF v_message IS NULL THEN
         IF v_check_index IS NULL AND v_against_index IS NOT NULL THEN
            v_message := message('Extra line found at end of reference collection: ' || 
                                  Preview_Line(against_this_in(v_against_index))     );
         ELSIF v_check_index IS NOT NULL AND v_against_index IS NULL THEN
            v_message := message('Extra line found at end of tested collection: ' || 
                                  Preview_Line(check_this_in(v_check_index))      );
         END IF;
      END IF;
      report (
         assert_name_in    => l_assert_name,
         check_this_in     => v_message IS NULL,
         msg_in            => msg_in,
         assert_details_in => NVL(v_message, message('Collections Match')),
         null_ok_in        => FALSE,
         raise_exc_in      => raise_exc_in);
   END eqoutput;

   ------------------------------------------------------------
   -- String & Delimiter Version Overload
   PROCEDURE eqoutput (
      msg_in                IN   VARCHAR2,
      check_this_in         IN   DBMS_OUTPUT.CHARARR,                     
      against_this_in       IN   VARCHAR2,
      line_delimiter_in     IN   CHAR := NULL,
      ignore_case_in        IN   BOOLEAN := FALSE,
      ignore_whitespace_in  IN   BOOLEAN := FALSE,
      null_ok_in            IN   BOOLEAN := TRUE,
      raise_exc_in          IN   BOOLEAN := FALSE
   )
   IS
      l_buffer        DBMS_OUTPUT.CHARARR;
      l_against_this  VARCHAR2(2000) := against_this_in;
      l_delimiter_pos BINARY_INTEGER; 
   BEGIN
      IF line_delimiter_in IS NULL THEN
         l_against_this := REPLACE(l_against_this, CHR(13)||CHR(10), CHR(10));
      END IF;
      WHILE l_against_this IS NOT NULL LOOP
         l_delimiter_pos := INSTR(l_against_this, NVL(line_delimiter_in, CHR(10)));
         IF l_delimiter_pos = 0 THEN
            l_buffer(l_buffer.COUNT) := l_against_this;
            l_against_this := NULL;
         ELSE
            l_buffer(l_buffer.COUNT) := SUBSTR(l_against_this, 1, l_delimiter_pos - 1);
            l_against_this := SUBSTR(l_against_this, l_delimiter_pos + 1);
            --Handle Case of delimiter at end
            IF l_against_this IS NULL THEN
               l_buffer(l_buffer.COUNT) := NULL;
            END IF;
         END IF;
      END LOOP;
      eqoutput(
         msg_in,
         check_this_in,                     
         l_buffer,
         ignore_case_in,
         ignore_whitespace_in,
         null_ok_in,
         raise_exc_in ); 
   END eqoutput;

   /* END chrisrimmer 42696 */

   /* START VENKY11 12345 */

/* Temporary Commented out for v3, may be moved to another package

   ------------------------------------------------------------
   --
   PROCEDURE eq_refc_table(
      p_msg_nm          IN   VARCHAR2,
      proc_name         IN   VARCHAR2,
      params            IN   utplsql_util3.utplsql_params,
      cursor_position   IN   PLS_INTEGER,
      table_name        IN   VARCHAR2 )
   IS
      refc_table_name VARCHAR2(50);
   BEGIN
      refc_table_name := utplsql_util3.prepare_and_fetch_rc (
                            proc_name,
                            params,
                            cursor_position,
                            1,
                            table_name );
      IF refc_table_name IS NOT NULL THEN
         --eqtable(p_msg_nm,'UTPLSQL.'||refc_table_name,table_name);
         eqtable(p_msg_nm, refc_table_name, table_name);
      END IF;
      utplsql_util3.execute_ddl('DROP TABLE ' || refc_table_name);
   END eq_refc_table;

   ------------------------------------------------------------
   --
   PROCEDURE eq_refc_query(
      p_msg_nm          IN   VARCHAR2,
      proc_name         IN   VARCHAR2,
      params            IN   utplsql_util3.utplsql_params,
      cursor_position   IN   PLS_INTEGER,
      qry               IN   VARCHAR2 )
   IS
      refc_table_name VARCHAR2(50);
   BEGIN
      refc_table_name := utplsql_util3.prepare_and_fetch_rc (
                            proc_name,
                            params,
                            cursor_position,
                            2,
                            qry);
      IF (refc_table_name IS NOT NULL) THEN
         --eqquery(p_msg_nm, 'select * from ' || 'UTPLSQL.' || refc_table_name, qry);
         eqquery(p_msg_nm, 'select * from ' || refc_table_name,qry);
      END IF;
      utplsql_util3.execute_ddl('DROP TABLE ' || refc_table_name);
   END eq_refc_query;
*/

   /* END VENKY11 12345 */

END utassert;
/
