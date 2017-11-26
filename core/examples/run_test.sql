
spool run_test
set serveroutput on size unlimited
set trimspool on

-- Run the test package
begin
   utplsql.run
      (package_name_in => 'ut_betwnstr'
      ,proc_prefix_in  => 'ut_');
end;
/

column testsuite_name  format a14
column testsuite_owner format a15
column testcase_name   format a15
column status          format a8
column profiler_runid  format 9999  heading RUNID
column runid           format 9999
column outcome_seq     format 9999  heading SEQ
column message         format a34
column assert_name     format a6    heading NAME
column assert_details  format a38
column errors          format a34   truncate
column run_comment     format a36   truncate
column run_comment1    format a36   truncate
column unit_number     format 9999  heading UNIT#
column line#           format 9999
column total_occur     format 9999  heading OCCUR
column total_time      format 9999999999
column min_time        format 9999999999
column max_time        format 9999999999
column unit_type       format a22
column unit_owner      format a22
column unit_name       format a22

-- Show Details of Code Coverage

prompt
prompt UTC_TESTSUITE:
prompt ==============
select testsuite_name      --  14
      ,testsuite_owner     --  16
      ,status              --   9
      ,profiler_runid      --   6
      ,errors              --  35 = 80
 from utc_testsuite
 order by testsuite_name
      ,testsuite_owner;

prompt
prompt UTC_TESTCASE:
prompt =============
select testsuite_name      --  14
      ,testcase_name       --  16
      ,status              --   9
      ,errors              --  35  = 74
 from  utc_testcase
 order by testsuite_name
      ,testsuite_owner
      ,start_on
      ,testcase_name;

prompt
prompt UTC_OUTCOME:
prompt ============
select testsuite_name      --  14
      ,testcase_name       --  16
      ,outcome_seq         --   6
      ,status              --   9
      ,message             --  35 = 80
      ,assert_name         --   6
      ,assert_details      --  39
      ,errors              --  35 = 80
 from  utc_outcome
 order by testsuite_name
      ,run_on
      ,testcase_name
      ,outcome_seq;

prompt
prompt PLSQL_PROFILER_RUNS:
prompt ====================
select runid               --   5
      ,run_comment         --  37
      ,run_comment1        --  37 = 79
 from  plsql_profiler_runs
 order by runid
      ,run_date;

prompt
prompt PLSQL_PROFILER_UNITS:
prompt =====================
select runid               --   5
      ,unit_number         --   6
      ,unit_type           --  23
      ,unit_owner          --  23
      ,unit_name           --  23 = 80
 from  plsql_profiler_units
 order by runid
      ,unit_number;

prompt
prompt PLSQL_PROFILER_DATA:
prompt ====================
select runid               --   5
      ,unit_number         --   6
      ,line#               --   6
      ,total_occur         --   6
      ,total_time          --  11
      ,min_time            --  11
      ,max_time            --  11 = 56
 from plsql_profiler_data
 order by runid
      ,unit_number
      ,line#;

-- select * from utc_codecoverage_v;

spool off
