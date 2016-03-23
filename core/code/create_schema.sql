
-- This is unfinished, a place holder for more rigorous installation scripts

set define off

-- Create Tables
@@create_proftab.sql
@@utc_not_executable.sql
@@utc_testsuite.sql
@@utc_testcase.sql
@@utc_outcome.sql

-- Create Package Sepecifications
@@ut_outputreporter.pks
/
@@ut_report.pks
/
@@ut_codecoverage.pks
/
@@ut_plsql.pks
/
@@ut_assert.pks
/

-- Create Views
@@utc_codecoverage_v.sql

-- Create Package Bodies
@@ut_outputreporter.pkb
/
@@ut_report.pkb
/
@@ut_codecoverage.pkb
/
@@ut_plsql.pkb
/
@@ut_assert.pkb
/
