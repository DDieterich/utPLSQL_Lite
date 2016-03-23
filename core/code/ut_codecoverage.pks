create or replace package utcodecoverage
AUTHID CURRENT_USER
as 

   FUNCTION version
      return varchar2;

   FUNCTION get_error_msg
      (retnum_in  in  binary_integer)
   return varchar2;

   -- Set the Database Object Under Test for Code Coverage
   PROCEDURE set_dout
      (dout_name_in   in  varchar2
      ,dout_type_in   in  varchar2
      ,dout_owner_in  in  varchar2);

   -- Returns the RUNID
   FUNCTION start_profiler
      (run_comment_in   in  varchar2)
   return binary_integer;

   PROCEDURE pause_profiler;

   PROCEDURE resume_profiler;

   -- DBMS_PROFILER.FLUSH_DATA is included with DBMS_PROFILER.STOP_PROFILER
   PROCEDURE stop_profiler;

   FUNCTION trigger_offset
      (dout_name_in   in  varchar2
      ,dout_type_in   in  varchar2
      ,dout_owner_in  in  varchar2)
   return number;

   FUNCTION calc_pct_coverage
      (profiler_runid_in  in  binary_integer)
   return number;

END utcodecoverage;
