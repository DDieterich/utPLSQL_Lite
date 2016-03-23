create or replace package body utcodecoverage
as

   g_dout_name   VARCHAR2(128);
   g_dout_type   VARCHAR2(20);
   g_dout_owner  VARCHAR2(128);
   g_runid       binary_integer;

------------------------------------------------------------
-----------------------   PUBLIC   -------------------------
------------------------------------------------------------

------------------------------------------------------------
--
function version
   return varchar2
is
begin
   return '3.0.1';
end version;

------------------------------------------------------------
-- Return DBMS_PROFILER specific error messages
function get_error_msg
      (retnum_in  in  binary_integer)
   return varchar2
is
   msg_prefix  varchar2(50) := 'DBMS_PROFILER Error: ';
begin
   case retnum_in
   when dbms_profiler.error_param then return msg_prefix ||
       'A subprogram was called with an incorrect parameter.';
   when dbms_profiler.error_io then return msg_prefix ||
       'Data flush operation failed.' ||
       ' Check whether the profiler tables have been created,' ||
       ' are accessible, and that there is adequate space.';
   when dbms_profiler.error_version then return msg_prefix ||
       'There is a mismatch between package and database implementation.' ||
       ' Oracle returns this error if an incorrect version of the' ||
       ' DBMS_PROFILER package is installed, and if the version of the' ||
       ' profiler package cannot work with this database version.';
   else return msg_prefix ||
       'Unknown error number ' || retnum_in;
   end case;
end get_error_msg;

------------------------------------------------------------
-- Set the Database Object Under Test for the Test Suite
procedure set_dout
      (dout_name_in   in  varchar2
      ,dout_type_in   in  varchar2
      ,dout_owner_in  in  varchar2)
is
   type_str    varchar2(1000);
   owner_str   varchar2(1000);
   obj_id      number;
begin
   g_runid      := null;
   g_dout_name  := '';
   g_dout_type  := '';
   g_dout_owner := '';
   type_str  := nvl(dout_type_in, 'PACKAGE');
   owner_str := nvl(dout_owner_in, user);
   select min(object_id) into obj_id
    from  all_objects
    where upper(object_name)  = upper(dout_name_in)
     and  upper(object_type)  = upper(type_str)
     and  upper(owner)        = upper(owner_str);
   select object_name, object_type, owner
    into  g_dout_name, g_dout_type, g_dout_owner
    from  all_objects
    where object_id = obj_id;
EXCEPTION
   when NO_DATA_FOUND then
      g_dout_name  := '';
      g_dout_type  := '';
      g_dout_owner := '';
      raise_application_error(-20000,
            'Unable to find ' || type_str ||
                     ' name ' || dout_name_in ||
         ' for schema owner ' || owner_str);
end set_dout;

------------------------------------------------------------
--
FUNCTION start_profiler
      (run_comment_in   in  varchar2)
   return binary_integer
IS
   retnum  binary_integer;
BEGIN
   stop_profiler;
   if g_dout_type is not null and
      g_dout_type in ('PACKAGE','PROCEDURE','FUNCTION','TRIGGER','TYPE')
   then
      retnum := dbms_profiler.INTERNAL_VERSION_CHECK;
      if retnum <> 0 then
         raise_application_error(-20000,
            'dbms_profiler.INTERNAL_VERSION_CHECK returned: ' || get_error_msg(retnum));
      end if;
      dbms_profiler.START_PROFILER(run_comment  => run_comment_in
                                  ,run_comment1 => 'Profiling ' || g_dout_type  ||
                                                            ' ' || g_dout_owner ||
                                                            '.' || g_dout_name  
                                  ,run_number   => g_runid);
   end if;
   -- Immediately Pause the profiler
   pause_profiler;
   -- Return the Run Number
   return g_runid;
END start_profiler;

------------------------------------------------------------
-- 
PROCEDURE pause_profiler
IS
BEGIN
   if g_runid is null
   then
      return;
   end if;
   dbms_profiler.PAUSE_PROFILER;
END pause_profiler;

------------------------------------------------------------
-- 
PROCEDURE resume_profiler
IS
BEGIN
   if g_runid is null
   then
      return;
   end if;
   dbms_profiler.RESUME_PROFILER;
END resume_profiler;

------------------------------------------------------------
--
PROCEDURE stop_profiler
IS
   procedure clean_other_runid
   is
      type runid_nt_type is table of plsql_profiler_units.runid%TYPE;
      runid_nt   runid_nt_type;
   begin
      -- Clean all data not in this Run Number
      select distinct runid bulk collect into runid_nt
       from  plsql_profiler_units
       where runid     <> g_runid
        and  unit_name  = g_dout_name
        and  unit_owner = g_dout_owner
        and  (   unit_type = g_dout_type
              or unit_type = g_dout_type || ' BODY');
      for i in 1 .. runid_nt.COUNT
      loop
         delete from plsql_profiler_data
          where runid = runid_nt(i);
         delete from plsql_profiler_units
          where runid = runid_nt(i);
         delete from plsql_profiler_runs
          where runid = runid_nt(i);
      end loop;
   end clean_other_runid;
   procedure clean_other_unit
   is
      type unit_number_nt_type is table of plsql_profiler_units.unit_number%TYPE;
      unit_number_nt  unit_number_nt_type;
   begin
      -- Clean only Run Number that was captured
      select distinct unit_number bulk collect into unit_number_nt
       from  plsql_profiler_units
       where runid = g_runid
        and  (   unit_name  <> g_dout_name
              or unit_owner <> g_dout_owner
              or (    unit_type <> g_dout_type
                  and unit_type <> g_dout_type || ' BODY') );
      for i in 1 .. unit_number_nt.COUNT
      loop
         delete from plsql_profiler_data
          where runid       = g_runid
           and  unit_number = unit_number_nt(i);
         delete from plsql_profiler_units
          where runid = g_runid
           and  unit_number = unit_number_nt(i);
      end loop;
   end clean_other_unit;
BEGIN
   if g_runid is null
   then
      return;
   end if;
   -- DBMS_PROFILER.FLUSH_DATA is included with DBMS_PROFILER.STOP_PROFILER
   dbms_profiler.stop_profiler;
   clean_other_runid;
   clean_other_unit;
   g_runid      := null;
   g_dout_name  := '';
   g_dout_type  := '';
   g_dout_owner := '';
END stop_profiler;

------------------------------------------------------------
--
FUNCTION trigger_offset
      (dout_name_in   in  varchar2
      ,dout_type_in   in  varchar2
      ,dout_owner_in  in  varchar2)
   return number
IS
BEGIN
   if nvl(dout_type_in,'BOGUS') <> 'TRIGGER' then
      return 0;
   end if;
   for buff in (
      select line, text from all_source
       where name  = dout_name_in
        and  type  = dout_type_in
        and  owner = dout_owner_in
      order by line )
   loop
      if regexp_instr(buff.text,
                      '(^declare$' ||
                      '|^declare[[:space:]]' ||
                      '|[[:space:]]declare$' ||
                      '|[[:space:]]declare[[:space:]])', 1, 1, 0, 'i') <> 0
         OR
         regexp_instr(buff.text,
                      '(^begin$' ||
                      '|^begin[[:space:]]' ||
                      '|[[:space:]]begin$' ||
                      '|[[:space:]]begin[[:space:]])', 1, 1, 0, 'i') <> 0 
      then
         return buff.line - 1;
      end if;
   end loop;
   return 0;
END trigger_offset;

------------------------------------------------------------
--
FUNCTION calc_pct_coverage
      (profiler_runid_in  in  binary_integer)
   return number
IS
   coverage_pct        number;
BEGIN
   with q1 as (
        select ccv.line#
              ,case when (    ccv.total_occur = 0
                          and ccv.total_time  = 0) then 0
                                                   else 1
               end                  hit
         from  utc_codecoverage_v  ccv
         where ccv.runid = profiler_runid_in
          and  (   ccv.total_occur != 0 and ccv.total_time != 0
                or ccv.total_occur  = 0 and ccv.total_time  = 0 )
          and  not exists (select 'x' from utc_not_executable ne
                            where ne.text = ccv.text            )
   )
   select 100 * nvl(sum(hit),0) /
          case count(line#) when 0 then 1
                                   else count(line#)
          end
    into  coverage_pct
    from  q1;
   return coverage_pct;
END calc_pct_coverage;

end utcodecoverage;
