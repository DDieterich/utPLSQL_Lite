
-- This is unfinished, a place holder for more rigorous installation scripts

------------------------------------------------------------
--
grant select, insert, update, delete on utc.plsql_profiler_runs to public;
create public synonym plsql_profiler_runs for utc.plsql_profiler_run;

grant select, insert, update, delete on utc.plsql_profiler_units to public;
create public synonym plsql_profiler_units for utc.plsql_profiler_units;

grant select, insert, update, delete on utc.plsql_profiler_data to public;
create public synonym plsql_profiler_data for utc.plsql_profiler_data;

------------------------------------------------------------
--
grant select, insert, update, delete on utc.utc_not_executable to public;
create public synonym utc_not_executable for utc.utc_not_executable;

grant select, insert, update, delete on utc.utc_testsuite to public;
create public synonym utc_testsuite for utc.utc_testsuite;

grant select, insert, update, delete on utc.utc_testcase to public;
create public synonym utc_testcase for utc.utc_testcase;

grant select, insert, update, delete on utc.utc_outcome to public;
create public synonym utc_outcome for utc.utc_outcome;

------------------------------------------------------------
--
grant execute on utc.utoutputreporter to public;
create public synonym utoutputreporter for utc.utoutputreporter;

grant execute on utc.utreport to public;
create public synonym utreport for utc.utreport;

grant execute on utc.utcodecoverage to public;
create public synonym utcodecoverage for utc.utcodecoverage;

grant execute on utc.utplsql to public;
create public synonym utplsql for utc.utplsql;

grant execute on utc.utassert to public;
create public synonym utassert for utc.utassert;

------------------------------------------------------------
--
grant select on utc.utc_codecoverage_v to public;
create public synonym utc_codecoverage_v for utc.utc_codecoverage_v;
