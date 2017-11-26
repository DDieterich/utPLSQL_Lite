CREATE OR REPLACE PACKAGE BODY utoutputreporter
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
Revision 3.0  2106/04/04 Duane Dieterich
Converted to v3

************************************************************************/

   -- Current Test Suite Record
   g_testsuite_rec  utc_testsuite%ROWTYPE;

   -- Private Globals
   g_show_failures_only   boolean := FALSE;
   g_no_results           boolean;
   g_no_test_errors       boolean;


------------------------------------------------------------
-- This is an interface to dbms_output.put_line that tries to
-- sensibly split long lines (which is useful if you want to
-- print large dynamic sql statements). From Alistair Bayley
PROCEDURE show
      (s                VARCHAR2
      ,maxlinelenparm   NUMBER    := 255
      ,expand           BOOLEAN   := TRUE)
IS
   output_buffer_overflow   EXCEPTION;
   PRAGMA EXCEPTION_INIT (output_buffer_overflow, -20000);
   i           NUMBER;
   maxlinelen  NUMBER := GREATEST (1, LEAST (255, maxlinelenparm));
   FUNCTION locatenewline (str VARCHAR2) RETURN NUMBER IS
      i10   NUMBER;
      i13   NUMBER;
   BEGIN
      i13 := NVL (INSTR (SUBSTR (str, 1, maxlinelen), CHR (13)), 0);
      i10 := NVL (INSTR (SUBSTR (str, 1, maxlinelen), CHR (10)), 0);
      IF i13 = 0 THEN
         RETURN i10;
      ELSIF i10 = 0 THEN
         RETURN i13;
      ELSE
         RETURN LEAST (i13, i10);
      END IF;
   END locatenewline;
BEGIN
   IF s IS NULL THEN
      DBMS_OUTPUT.put_line (s);
      -- PBA we should return here...
      RETURN;
   ELSIF LENGTH (s) <= maxlinelen THEN
      -- Simple case: s is short.
      DBMS_OUTPUT.put_line (s);
      RETURN;
   END IF;
   -- OK, so it's long. Look for newline chars as a good place to split.
   i := locatenewline (s);
   IF i > 0 THEN
      -- cool, we can split at a newline
      DBMS_OUTPUT.put_line (SUBSTR (s, 1, i - 1));
      show (SUBSTR (s, i + 1), maxlinelen, expand);
   ELSE
      -- No newlines. Look for a convenient space prior to the 255-char limit.
      -- Search backwards from maxLineLen.
      i := NVL (INSTR (SUBSTR (s, 1, maxlinelen), ' ', -1), 0);
      IF i > 0 THEN
         DBMS_OUTPUT.put_line (SUBSTR (s, 1, i - 1));
         show (SUBSTR (s, i + 1), maxlinelen, expand);
      ELSE
         -- No whitespace - split at max line length.
         i := maxlinelen;
         DBMS_OUTPUT.put_line (SUBSTR (s, 1, i));
         show (SUBSTR (s, i + 1), maxlinelen, expand);
      END IF;
   END IF;
EXCEPTION
   WHEN output_buffer_overflow THEN
      IF NOT expand THEN
         RAISE;
      ELSE
         DBMS_OUTPUT.ENABLE (1000000);
         -- set false so won't expand again
         show (s, maxlinelen, FALSE);
      END IF;
END show;

------------------------------------------------------------
--
PROCEDURE showbanner
   (success_in   IN   BOOLEAN
   ,program_in   IN   VARCHAR2)
IS
   program_name  VARCHAR2(2000);
BEGIN
   IF success_in THEN
      pl ('. ');
      pl ('>    SSSS   U     U   CCC     CCC   EEEEEEE   SSSS     SSSS   ');
      pl ('>   S    S  U     U  C   C   C   C  E        S    S   S    S  ');
      pl ('>  S        U     U C     C C     C E       S        S        ');
      pl ('>   S       U     U C       C       E        S        S       ');
      pl ('>    SSSS   U     U C       C       EEEE      SSSS     SSSS   ');
      pl ('>        S  U     U C       C       E             S        S  ');
      pl ('>         S U     U C     C C     C E              S        S ');
      pl ('>   S    S   U   U   C   C   C   C  E        S    S   S    S  ');
      pl ('>    SSSS     UUU     CCC     CCC   EEEEEEE   SSSS     SSSS   ');
   ELSE
      pl ('. ');
      pl ('>  FFFFFFF   AA     III  L      U     U RRRRR   EEEEEEE ');
      pl ('>  F        A  A     I   L      U     U R    R  E       ');
      pl ('>  F       A    A    I   L      U     U R     R E       ');
      pl ('>  F      A      A   I   L      U     U R     R E       ');
      pl ('>  FFFF   A      A   I   L      U     U RRRRRR  EEEE    ');
      pl ('>  F      AAAAAAAA   I   L      U     U R   R   E       ');
      pl ('>  F      A      A   I   L      U     U R    R  E       ');
      pl ('>  F      A      A   I   L       U   U  R     R E       ');
      pl ('>  F      A      A  III  LLLLLLL  UUU   R     R EEEEEEE ');
   END IF;
   pl ('. ');
   program_name := '"'||NVL (program_in, 'Unnamed Test')||'"';
   IF success_in THEN
      pl (' SUCCESS: ' || program_name);
   ELSE
      pl (' FAILURE: ' || program_name);
   END IF;
   pl ('. ');
END showbanner;

------------------------------------------------------------
--
PROCEDURE before_results
IS
   is_success  boolean := (g_testsuite_rec.status = utreport.c_SUCCESS);
   num_fails   number;
   num_errs    number;
BEGIN
   showbanner (is_success, g_testsuite_rec.testsuite_name);
   if not is_success
   then
      select count(*)
       into  num_fails
       from  utc_outcome
       where testsuite_name  = g_testsuite_rec.testsuite_name
        and  testsuite_owner = g_testsuite_rec.testsuite_owner
        and  status          = utreport.c_FAILURE;
      with tcase as (
           select count(*)  num_errors
            from  utc_testcase
            where testsuite_name  = g_testsuite_rec.testsuite_name
             and  testsuite_owner = g_testsuite_rec.testsuite_owner
             and  errors is not null
      ), tsuite as (
           select count(*)  num_errors
            from  utc_testsuite
            where testsuite_name  = g_testsuite_rec.testsuite_name
             and  testsuite_owner = g_testsuite_rec.testsuite_owner
             and  errors is not null
      )
      select tcase.num_errors + tsuite.num_errors
       into  num_errs
       from  tcase cross join tsuite;
      pl ('> ' || num_fails || ' Failures and ' || num_errs || ' Errors');
      pl ('>');
   end if;
   pl ('> Individual Test Case Results:');
   pl ('>');
   g_no_results := TRUE;
END before_results;

------------------------------------------------------------
--
PROCEDURE show_failure
       (utc_outcome_in  in  utc_outcome%ROWTYPE)
IS
BEGIN
   pl (utc_outcome_in.status         || ' - ' || 
       utc_outcome_in.testsuite_name || '.' ||
       utc_outcome_in.testcase_name  || ': ' ||
       /* 2.0.10.2 Idea from Alistair Bayley msg_in */
       -- AssertName "Message" Assert Details
       utc_outcome_in.assert_name    || ' "' || 
       utc_outcome_in.message        || '" ' ||
       utc_outcome_in.assert_details );
   if utc_outcome_in.errors is not null then
      pl ('Errors: ' || utc_outcome_in.errors);
   end if;
   pl ('>');
   g_no_results := FALSE;
END show_failure;

------------------------------------------------------------
--
PROCEDURE after_results
IS
BEGIN
   IF g_no_results AND g_show_failures_only
   THEN
      pl ('> NO FAILURES FOUND');
   ELSIF g_no_results THEN
      pl ('> NONE FOUND');
   END IF;
END after_results;

------------------------------------------------------------
--
PROCEDURE before_errors
IS
BEGIN
   pl ('>');
   pl ('> Errors recorded:');
   pl ('>');
   g_no_test_errors := TRUE;
END before_errors;

------------------------------------------------------------
--
PROCEDURE show_error
      (header_in  in  varchar2
      ,errors_in  in  varchar2)
IS
BEGIN
   g_no_test_errors := FALSE;
   pl (header_in || ' Errors: ' || errors_in);
END show_error;

------------------------------------------------------------
--
PROCEDURE after_errors
IS
BEGIN
   IF g_no_test_errors THEN
      pl ('> NONE FOUND');
   END IF;
END after_errors;

------------------------------------------------------------
--
PROCEDURE show_coverage
IS
   prof_run_rec   plsql_profiler_runs%ROWTYPE;
BEGIN
   If g_testsuite_rec.profiler_runid is null then
      return;
   end if;
   pl ('>');
   select * into prof_run_rec
    from  plsql_profiler_runs
    where runid = g_testsuite_rec.profiler_runid;
   pl ('> ' ||
       to_char(utcodecoverage.calc_pct_coverage
                 (profiler_runid_in => g_testsuite_rec.profiler_runid)
              ,'999.99'                                               ) ||
       '% code coverage ' || prof_run_rec.run_comment1);
EXCEPTION WHEN no_data_found THEN
   pl ('> No Profiler Data for RunID ' || g_testsuite_rec.profiler_runid);
END show_coverage;


------------------------------------------------------------
-----------------------   PUBLIC   -------------------------
------------------------------------------------------------


------------------------------------------------------------
--
FUNCTION version
   RETURN varchar2
IS
BEGIN
   return '3.0.1';
END version;

------------------------------------------------------------
--  Used to confirm this package exists.
PROCEDURE no_op IS BEGIN null; END no_op;

------------------------------------------------------------
--  Used by utPLSQL for Ad-Hoc Assert Reporting.
PROCEDURE pl (str_in VARCHAR2)
IS
BEGIN
   show(str_in);
END pl;

------------------------------------------------------------
--
PROCEDURE show_result
       (utc_outcome_in  in  utc_outcome%ROWTYPE)
IS
BEGIN
   pl (utc_outcome_in.status         || ' - ' || 
       utc_outcome_in.testsuite_name || '.' ||
       utc_outcome_in.testcase_name  || ': ' ||
       /* 2.0.10.2 Idea from Alistair Bayley msg_in */
       utc_outcome_in.assert_name    || ' "' || 
       utc_outcome_in.message        || '" ' ||
       utc_outcome_in.assert_details );
   pl ('>');
   g_no_results := FALSE;
END show_result;

------------------------------------------------------------
-- Reporter Show Failures Only
PROCEDURE showfailuresonly
      (onoff_in  IN  BOOLEAN)
IS
BEGIN
   g_show_failures_only := onoff_in;
END showfailuresonly;

------------------------------------------------------------
--
PROCEDURE show_all
      (testsuite_name_in   IN  VARCHAR2
      ,testsuite_owner_in  IN  VARCHAR2 default user)
IS
BEGIN
   g_testsuite_rec.testsuite_name  := testsuite_name_in;
   g_testsuite_rec.testsuite_owner := testsuite_owner_in;
   select * into g_testsuite_rec
    from  utc_testsuite
    where testsuite_name  = g_testsuite_rec.testsuite_name
     and  testsuite_owner = g_testsuite_rec.testsuite_owner;
   before_results;
   FOR rec IN (SELECT * FROM utc_outcome
                WHERE testsuite_name = g_testsuite_rec.testsuite_name
                ORDER BY testcase_name, outcome_seq)
   LOOP
      IF rec.status = utreport.c_FAILURE
      THEN
         show_failure(rec);
      ELSIF not g_show_failures_only
      THEN
         show_result(rec);
      END IF;
   END LOOP;
   after_results;
   before_errors;
   FOR rec in (SELECT * from utc_testcase
                WHERE testsuite_name = g_testsuite_rec.testsuite_name
                ORDER BY testcase_name)
   LOOP
      if rec.errors is not null then
         show_error('Test Case ' || rec.testcase_name, rec.errors);
      end if;
   END LOOP;
   if g_testsuite_rec.errors is not null then
      show_error('Test Suite ' || g_testsuite_rec.testsuite_name
                ,g_testsuite_rec.errors);
   end if;
   after_errors;
   show_coverage;
END show_all;

END utoutputreporter;
