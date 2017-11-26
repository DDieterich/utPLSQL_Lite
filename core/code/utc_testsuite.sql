
create
   global temporary
   table utc_testsuite
   (testsuite_name   VARCHAR2(128) CONSTRAINT utc_testsuite_nn1 NOT NULL
   ,testsuite_owner  VARCHAR2(128) CONSTRAINT utc_testsuite_nn2 NOT NULL
   ,status           VARCHAR2(8)   CONSTRAINT utc_testsuite_nn3 NOT NULL
   ,start_on         timestamp(9)  CONSTRAINT utc_testsuite_nn4 NOT NULL
   ,profiler_runid   number
   ,end_on           timestamp(9)
   ,errors           VARCHAR2(4000)
   ,constraint utc_testsuite_pk primary key (testsuite_name, testsuite_owner)
   --,constraint utc_testsuite_fk1 foreign key (profiler_runid)
   --    references plsql_profiler_runs (runid)
   ,constraint utc_testsuite_uk1 unique (profiler_runid)
   ,constraint utc_testsuite_ck1 check (status in ('RUNNING','SUCCESS','FAILURE'))
   )
   on commit preserve rows
   ;

comment on table utc_testsuite is 'List of current test suites';
comment on column utc_testsuite.testsuite_name  is 'Test suite name, primary key 1 of 2';
comment on column utc_testsuite.testsuite_owner is 'Test suite owner, primary key 2 of 2';
comment on column utc_testsuite.status          is 'Current status of this test suite: RUNNING, SUCCESS, FAILURE';
comment on column utc_testsuite.start_on        is 'Date/time this test suite started';
comment on column utc_testsuite.profiler_runid  is 'Unique DBMS_PROFILER RunID for code coverage';
comment on column utc_testsuite.end_on          is 'Date/time this test suite ended';
comment on column utc_testsuite.errors          is 'Errors that occured at the test suite level';
