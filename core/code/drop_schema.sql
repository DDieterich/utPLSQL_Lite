
-- This is unfinished, a place holder for more rigorous installation scripts

-- Drop Views
drop view utc_codecoverage_v;

-- Drop Packages
drop package utassert;
drop package utplsql;
drop package utcodecoverage;
drop package utreport;
drop package utoutputreporter;

-- Drop Tables
drop table utc_outcome;
drop table utc_testcase;
drop table utc_testsuite;
drop table utc_not_executable;

-- Drop DBMS_PROFILER Tables
@drop_proftab.sql
