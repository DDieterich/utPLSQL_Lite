create or replace package body utplsql
is

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

   subtype testcase_type is varchar2(15);

   -- Private Constants
   LF               CONSTANT varchar2(1)  := CHR(10);
   c_init_proc      CONSTANT testcase_type := 'UTPLSQL_INIT';
   c_final_proc     CONSTANT testcase_type := 'UTPLSQL_FINAL';
   c_setup          CONSTANT testcase_type := 'SETUP';
   c_teardown       CONSTANT testcase_type := 'TEARDOWN';
   c_runit          CONSTANT testcase_type := 'RUNIT';
   c_skipit         CONSTANT testcase_type := 'SKIPIT';

   -- Current Test Suite Record
   g_testsuite_rec  utc_testsuite%ROWTYPE;

   -- Current Test Case Record and nested table of Names/Types
   g_testcase_rec   utc_testcase%ROWTYPE;
   TYPE tc_nt_rec_type is record
      (name   all_arguments.object_name%TYPE
      ,type   testcase_type);
   TYPE tc_nt_type is table of tc_nt_rec_type;
   g_tc_nt    tc_nt_type;

   -- Private Globals
   g_halt_on_exception  boolean := FALSE;
   g_last_outcome_seq   integer;


------------------------------------------------------------
-- Save Test Suite Data
procedure save_testsuite
is
   -- PRAGMA AUTONOMOUS_TRANSACTION not needed
begin
   update utc_testsuite
     set  status         = g_testsuite_rec.status
         ,start_on       = g_testsuite_rec.start_on
         ,profiler_runid = g_testsuite_rec.profiler_runid
         ,end_on         = g_testsuite_rec.end_on
         ,errors         = g_testsuite_rec.errors
    where testsuite_name  = g_testsuite_rec.testsuite_name
     and  testsuite_owner = g_testsuite_rec.testsuite_owner;
   if SQL%ROWCOUNT = 0
   then
      insert into utc_testsuite values g_testsuite_rec;
   end if;
   commit;
end save_testsuite;


------------------------------------------------------------
-- Reset Test Suite Data
procedure reset_testsuite
      (package_name_in   in  varchar2
      ,package_owner_in  in  varchar2)
is
   -- PRAGMA AUTONOMOUS_TRANSACTION not needed
   empty_testsuite_rec  utc_testsuite%ROWTYPE;
   empty_testcase_rec   utc_testcase%ROWTYPE;
   PROCEDURE set_testsuite_name IS
      owner_str   varchar2(1000);
      obj_id      number;
   BEGIN
      owner_str := nvl(package_owner_in, user);
      select min(object_id) into obj_id
       from  all_objects
       where upper(object_name) = upper(package_name_in)
        and  object_type        = 'PACKAGE'
        and  upper(owner)       = upper(owner_str);
      select object_name,                    owner
       into  g_testsuite_rec.testsuite_name, g_testsuite_rec.testsuite_owner
       from  all_objects
       where object_id = obj_id;
   EXCEPTION
      when NO_DATA_FOUND then
         g_testsuite_rec.testsuite_name  := '';
         g_testsuite_rec.testsuite_owner := '';
         raise_application_error(-20000,
            'Unable to find package name ' || package_name_in ||
            ' for schema owner ' || owner_str);
   END set_testsuite_name;
begin
   g_testsuite_rec.testsuite_name := '';
   set_testsuite_name;
   -- Exception thrown if test stuite name not set
   delete from utc_outcome
    where testsuite_name  = g_testsuite_rec.testsuite_name
     and  testsuite_owner = g_testsuite_rec.testsuite_owner;
   delete from utc_testcase
    where testsuite_name  = g_testsuite_rec.testsuite_name
     and  testsuite_owner = g_testsuite_rec.testsuite_owner;
   delete from utc_testsuite
    where testsuite_name  = g_testsuite_rec.testsuite_name
     and  testsuite_owner = g_testsuite_rec.testsuite_owner;
   empty_testsuite_rec.testsuite_name  := g_testsuite_rec.testsuite_name;
   empty_testsuite_rec.testsuite_owner := g_testsuite_rec.testsuite_owner;
   g_testsuite_rec          := empty_testsuite_rec;
   g_testsuite_rec.status   := utreport.c_RUNNING;
   g_testsuite_rec.start_on := systimestamp;
   save_testsuite;
   g_testcase_rec := empty_testcase_rec;
end reset_testsuite;


------------------------------------------------------------
--
PROCEDURE start_profiler
IS
BEGIN
   g_testsuite_rec.profiler_runid :=
      utcodecoverage.start_profiler
         (run_comment_in  => 'utPLSQL Profiling from ' ||
                              g_testsuite_rec.testsuite_owner ||
                       '.' || g_testsuite_rec.testsuite_name);
   if g_testsuite_rec.profiler_runid is not null
   then
      save_testsuite;
   end if;
END start_profiler;


------------------------------------------------------------
--
PROCEDURE stop_profiler
IS
BEGIN
   utcodecoverage.STOP_PROFILER;
END stop_profiler;


------------------------------------------------------------
--
PROCEDURE resume_profiler
IS
BEGIN
   utcodecoverage.RESUME_PROFILER;
END resume_profiler;


------------------------------------------------------------
--
PROCEDURE pause_profiler
IS
BEGIN
   utcodecoverage.PAUSE_PROFILER;
END pause_profiler;


------------------------------------------------------------
-- Save Test Case Data
procedure save_testcase
is
   PRAGMA AUTONOMOUS_TRANSACTION;
begin
   update utc_testcase
     set  status   = g_testcase_rec.status
         ,start_on = g_testcase_rec.start_on
         ,end_on   = g_testcase_rec.end_on
         ,errors   = g_testcase_rec.errors
    where testsuite_name  = g_testcase_rec.testsuite_name
     and  testsuite_owner = g_testcase_rec.testsuite_owner
     and  testcase_name   = g_testcase_rec.testcase_name;
   if SQL%ROWCOUNT = 0
   then
      insert into utc_testcase values g_testcase_rec;
   end if;
   commit;
end save_testcase;


------------------------------------------------------------
--
PROCEDURE load_testcase_names
      (proc_prefix_in       IN  VARCHAR2 default '')
IS
BEGIN
   -- If no rows are selected, g_testcase_names_nt is initialized
   --    with zero records
   SELECT object_name      name
         ,null             type
    BULK COLLECT INTO g_tc_nt
    FROM  all_arguments
    WHERE owner         = g_testsuite_rec.testsuite_owner
     AND  package_name  = g_testsuite_rec.testsuite_name
     AND  position      = 1
     AND  argument_name is null
    ORDER BY object_name;
   for i in 1 .. g_tc_nt.COUNT
   loop
      case
      when upper(g_tc_nt(i).name) = c_init_proc
      then
           g_tc_nt(i).type := c_init_proc;
      when upper(g_tc_nt(i).name) = c_final_proc
      then
           g_tc_nt(i).type := c_final_proc;
      when proc_prefix_in is not null   and
           upper(g_tc_nt(i).name) = upper(proc_prefix_in)||c_setup
      then
           g_tc_nt(i).type := c_setup;
      when proc_prefix_in is not null   and
           upper(g_tc_nt(i).name) = upper(proc_prefix_in)||c_teardown
      then
           g_tc_nt(i).type := c_teardown;
      when upper(g_tc_nt(i).name) like upper(proc_prefix_in)||'%'
      then
           g_tc_nt(i).type := c_runit;
      else 
           g_tc_nt(i).type := c_skipit;
      end case;
   end loop;
END load_testcase_names;


------------------------------------------------------------
--
PROCEDURE run_testcase
      (testcase_name_in IN  VARCHAR2)
IS
   empty_testcase_rec   utc_testcase%ROWTYPE;
   num_fails            integer;
BEGIN
   g_testcase_rec                 := empty_testcase_rec;
   g_testcase_rec.testsuite_name  := g_testsuite_rec.testsuite_name;
   g_testcase_rec.testsuite_owner := g_testsuite_rec.testsuite_owner;
   g_testcase_rec.testcase_name   := testcase_name_in;
   g_testcase_rec.status          := utreport.c_RUNNING;
   g_testcase_rec.start_on        := systimestamp;
   save_testcase;
   g_last_outcome_seq := 0;
   resume_profiler;
   execute immediate 'begin "' || g_testcase_rec.testsuite_owner ||
                         '"."' || g_testcase_rec.testsuite_name  ||
                         '"."' || g_testcase_rec.testcase_name   ||
                    '"; end;';
   pause_profiler;
   select count(*) into num_fails
    from  utc_outcome
    where testsuite_name  = g_testcase_rec.testsuite_name
     and  testsuite_owner = g_testcase_rec.testsuite_owner
     and  testcase_name   = g_testcase_rec.testcase_name
     and  (   status = utreport.c_FAILURE
           or errors is not null);
   if num_fails > 0
   then
      g_testcase_rec.status := utreport.c_FAILURE;
   else
      g_testcase_rec.status := utreport.c_SUCCESS;
   end if;
   g_testcase_rec.end_on := systimestamp;
   save_testcase;
EXCEPTION
   when others then
      -- Save the Test Case Error
      g_testcase_rec.errors := DBMS_UTILITY.FORMAT_ERROR_STACK  ||
                               DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ;
      g_testcase_rec.status := utreport.c_FAILURE;
      g_testcase_rec.end_on := systimestamp;
      save_testcase;
      -- Finish Cleanup
      pause_profiler;
END run_testcase;


------------------------------------------------------------
--
PROCEDURE run_pre_or_post
      (tc_type_in IN  VARCHAR2
      ,tc_indx_in IN  NUMBER  DEFAULT NULL)
IS
   testcase_name   utc_testcase.testcase_name%TYPE;
BEGIN
   FOR i in 1 .. g_tc_nt.COUNT
   LOOP
      if g_tc_nt(i).type = tc_type_in
      then
         testcase_name := g_tc_nt(i).name;
         -- Setup and Teardown can be run multiple times within a Test Suite.
         -- TC_INDX_IN is used to create unique Test Case Names.
         if tc_indx_in is not null
         then
            testcase_name := testcase_name || '_' ||
                             ltrim(to_char(tc_indx_in,'09'));
         end if;
         run_testcase(g_tc_nt(i).name || tc_indx_in);
      end if;
   END LOOP;
END run_pre_or_post;


------------------------------------------------------------
--
PROCEDURE skip_testcases
      (tc_nt_indx_in  IN  INTEGER)
IS
BEGIN
   g_testcase_rec.testsuite_name  := g_testsuite_rec.testsuite_name;
   g_testcase_rec.testsuite_owner := g_testsuite_rec.testsuite_owner;
   g_testcase_rec.status          := utreport.c_SKIPPED;
   FOR j in tc_nt_indx_in .. g_tc_nt.COUNT
   LOOP
      if g_tc_nt(j).type = c_runit
      then
         g_testcase_rec.testcase_name := g_tc_nt(j).name;
         g_testcase_rec.start_on      := systimestamp;
         save_testcase;
      end if;
   END LOOP;
 END skip_testcases;


------------------------------------------------------------
-----------------------   PUBLIC   -------------------------
------------------------------------------------------------


------------------------------------------------------------
--
function version
   return varchar2
is
begin
   return 'utPLSQL '          || '3.0.1'                  || LF ||
          'utAssert '         || utassert.version         || LF ||
         -- 'utAssert2 '        || utassert2.version        || LF ||
          'utCodeCoverage '   || utcodecoverage.version   || LF ||
          'utReport '         || utreport.version         || LF ||
          'utOutputReporter ' || utoutputreporter.version || LF ||
          '';
end version;


------------------------------------------------------------
-- Receive a report from an assertion
procedure report
      (assert_name_in    in  VARCHAR2
      ,test_failed_in    in  BOOLEAN
      ,message_in        in  VARCHAR2
      ,assert_details_in in  VARCHAR2  default ''
      ,errors_in         in  VARCHAR2  default ''
      ,register_in       in  BOOLEAN   default TRUE
      ,showresults_in    in  BOOLEAN   default TRUE)
is
   PRAGMA AUTONOMOUS_TRANSACTION;
   l_utc_outcome_rec  utc_outcome%ROWTYPE;
begin
   pause_profiler;
   l_utc_outcome_rec.assert_name    := assert_name_in;
   if not test_failed_in
   then
      l_utc_outcome_rec.status := utreport.c_SUCCESS;
   else
      -- Null test_failed_in will also arrive here.
      l_utc_outcome_rec.status := utreport.c_FAILURE;
   end if;
   l_utc_outcome_rec.message        := substr(message_in,1,4000);
   l_utc_outcome_rec.assert_details := substr(assert_details_in,1,4000);
   l_utc_outcome_rec.errors         := substr(errors_in,1,4000);
   if g_testsuite_rec.testsuite_name is null
   then
      if showresults_in
      then
         utreport.show_result(l_utc_outcome_rec);
      end if;
   else
      if register_in then
         g_last_outcome_seq := g_last_outcome_seq + 1;
         l_utc_outcome_rec.testsuite_name  := g_testsuite_rec.testsuite_name;
         l_utc_outcome_rec.testsuite_owner := g_testsuite_rec.testsuite_owner;
         l_utc_outcome_rec.testcase_name   := g_testcase_rec.testcase_name;
         l_utc_outcome_rec.outcome_seq     := g_last_outcome_seq;
         l_utc_outcome_rec.run_on          := systimestamp;
         insert into utc_outcome values l_utc_outcome_rec;
      end if;
   end if;
   resume_profiler;
   commit;
end report;

   
------------------------------------------------------------
-- Testcase Halt on Exceptions
PROCEDURE haltonexception
      (onoff_in  IN  BOOLEAN)
IS
BEGIN
   g_halt_on_exception := onoff_in;
END haltonexception;


------------------------------------------------------------
--
PROCEDURE run
      (package_name_in      IN  VARCHAR2
      ,package_owner_in     IN  VARCHAR2 default user
      ,showresults_in       IN  BOOLEAN  default TRUE
      ,proc_prefix_in       IN  VARCHAR2 default ''
      ,per_method_setup_in  IN  BOOLEAN := FALSE)
IS
   num_fails  number;
BEGIN
   ---------------------------------------------------------------------
   --------------------  Initialise the Test Suite  --------------------
   -- Populate the Test Suite
   -- Also clears everything related to this Test Suite
   reset_testsuite(package_name_in, package_owner_in);
   -- Find all the Test Case Names
   load_testcase_names(proc_prefix_in);
   -- Run utPLSQL_init
   run_pre_or_post(c_init_proc);
   start_profiler;  -- Resets profiler and sets the profiler runid and pauses
   -- Run setup if prefix is defined
   if not per_method_setup_in
   then
      run_pre_or_post(c_setup);
   end if;
   utreport.reset_reporter;
   ------------------------------------------------------------------
   --------------------  Loop on the Test Cases  --------------------
   -- Run the test cases
   FOR i in 1 .. g_tc_nt.COUNT
   LOOP
      if g_tc_nt(i).type = c_runit
      then
         if per_method_setup_in
         then
             -- Setup is being run for each Test Case
             run_pre_or_post(c_setup, i);
         end if;
         run_testcase(g_tc_nt(i).name);
         if  nvl(g_testcase_rec.status, utreport.c_FAILURE) <> utreport.c_SUCCESS
         then
            if g_halt_on_exception
            then
               skip_testcases(i+1);
               exit;  -- exit i loop
            end if;
         end if;
         if per_method_setup_in
         then
             -- Teardown is being run for each Test Case
            run_pre_or_post(c_teardown, i);
         end if;
      end if;
   END LOOP; -- i loop
   -------------------------------------------------------------------
   --------------------  Finalize the Test Suite  --------------------
   -- Run setup if prefix is defined
   if not per_method_setup_in
   then
      run_pre_or_post(c_teardown);
   end if;
   -- resume_profiler;  -- Not required???
   stop_profiler;  -- Also flushes profiler data to profiler tables
   -- Run utPLSQL_final
   run_pre_or_post(c_final_proc);
   -- Determine the Test Suite Status
   with q1 as (
        select 'x' from utc_testcase
         where testsuite_name  = g_testsuite_rec.testsuite_name
          and  testsuite_owner = g_testsuite_rec.testsuite_owner
          and  (   status = utreport.c_FAILURE
                or errors is not null)
          and  rownum = 1  -- One row a failure makes...
   )
   select count(*) into num_fails from q1;
   if num_fails > 0
   then
      g_testsuite_rec.status := utreport.c_FAILURE;
   else
      g_testsuite_rec.status := utreport.c_SUCCESS;
   end if;
   g_testsuite_rec.end_on := systimestamp;
   save_testsuite;
   --------------------------------------------------------------------
   --------------------  Report on the Test Suite  --------------------
   if showresults_in
   then
      utreport.run_act_reporter(g_testsuite_rec);
   end if;
EXCEPTION
   WHEN OTHERS THEN
      g_testsuite_rec.errors :=
         substr(DBMS_UTILITY.FORMAT_ERROR_STACK ||
                DBMS_UTILITY.FORMAT_ERROR_BACKTRACE
               ,1,4000);
      if g_testsuite_rec.testsuite_name is null
      then
         -- There is nowhere to report/save the error
         raise_application_error(-20000, g_testsuite_rec.errors);
      end if;
      -- Finalize the Test Suite with an error
      g_testsuite_rec.status := utreport.c_FAILURE;
      g_testsuite_rec.end_on := systimestamp;
      save_testsuite;
      -- Finish Cleanup
      stop_profiler;
END run;


end utplsql;