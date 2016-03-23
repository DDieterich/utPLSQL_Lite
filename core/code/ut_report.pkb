create or replace package body utreport
as

   -- Private Constants
   LF               CONSTANT varchar2(1)  := CHR(10);
   c_reporter_test  CONSTANT varchar2(30) := 'NO_OP';     -- Upper Case Only
   c_reporter_proc  CONSTANT varchar2(30) := 'SHOW_ALL';  -- Upper Case Only

   --This is the reporter we have been asked to use
   g_set_reporter   VARCHAR2(512) := NULL;
   --This is the reporter we are actually using
   --(this differs from the above in the event of error)
   g_act_reporter   VARCHAR2(512) := NULL;

   g_reporter_failover  boolean := TRUE;


------------------------------------------------------------
-----------------------   PUBLIC   -------------------------
------------------------------------------------------------


------------------------------------------------------------
--
function version
   return varchar2
as
begin
   return '3.0.1';
end version;

------------------------------------------------------------
--
PROCEDURE reset_reporter
IS
BEGIN
   -- Reset the reporter
   g_act_reporter := g_set_reporter;
END reset_reporter;


------------------------------------------------------------
--
PROCEDURE use_reporter
      (reporter_in IN VARCHAR2
      ,failover_in In BOOLEAN default TRUE)
IS
   reporter_str  varchar2(2000);
   num_rows      integer;
BEGIN
   reporter_str := '"' || reporter_in || '"."' || c_reporter_test || '"';
   g_set_reporter := null;
   begin
      -- Confirm the reporter has a working test procedure
      execute immediate 'begin ' || reporter_str || '; end;';
      g_set_reporter := reporter_in;
   exception when others then
      raise_application_error (-20000,
         'Unable to execute ' || reporter_str || ': ' || SQLERRM);
   end;
   if upper(g_set_reporter) = 'UTOUTPUTREPORTER' or
      upper(g_set_reporter) like '%.UTOUTPUTREPORTER'
   then
      g_set_reporter := null;
   end if;
   g_act_reporter := g_set_reporter;
   g_reporter_failover := failover_in;
END use_reporter;

------------------------------------------------------------
--
PROCEDURE show_result
       (utc_outcome_in  in  utc_outcome%ROWTYPE)
IS
BEGIN
   utoutputreporter.show_result(utc_outcome_in);
END show_result;

------------------------------------------------------------
--
PROCEDURE run_act_reporter
      (testsuite_rec_in  in  utc_testsuite%ROWTYPE)
IS
   err_msg    VARCHAR2(32000);
BEGIN
   if g_act_reporter is not NULL
   then
      execute immediate 'BEGIN "' || g_act_reporter  ||
                            '"."' || c_reporter_proc ||
                           '"(''' || testsuite_rec_in.testsuite_name ||
                         ''', ''' || testsuite_rec_in.testsuite_owner ||
                       '''); END;';
   else
      utoutputreporter.show_all(testsuite_rec_in.testsuite_name
                               ,testsuite_rec_in.testsuite_owner);
   end if;
EXCEPTION
   WHEN OTHERS THEN
      err_msg := '"' || g_set_reporter || '" Error' || LF ||
                 DBMS_UTILITY.FORMAT_ERROR_STACK  ||
                 DBMS_UTILITY.FORMAT_ERROR_BACKTRACE ;
      IF g_reporter_failover
      THEN
         g_act_reporter := NULL;
         utoutputreporter.pl(err_msg);
         utoutputreporter.pl('** REVERTING TO DEFAULT REPORTER **: UTOutputReporter');
         utoutputreporter.show_all(testsuite_rec_in.testsuite_name
                                  ,testsuite_rec_in.testsuite_owner);
      ELSE
         raise_application_error
            (-20000, substr('(No Reporter Failover) ' || err_msg, 1, 4000));
      END IF;
END run_act_reporter;


end utreport;