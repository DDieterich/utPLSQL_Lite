
create
   global temporary
   table utc_testcase
   (testsuite_name   VARCHAR2(128) CONSTRAINT utc_testcase_nn1 NOT NULL
   ,testsuite_owner  VARCHAR2(128) CONSTRAINT utc_testcase_nn2 NOT NULL
   ,testcase_name    VARCHAR2(128) CONSTRAINT utc_testcase_nn3 NOT NULL
   ,status           VARCHAR2(8)   CONSTRAINT utc_testcase_nn4 NOT NULL
   ,start_on         timestamp(9)  CONSTRAINT utc_testcase_nn5 NOT NULL
   ,end_on           timestamp(9)
   ,errors           VARCHAR2(4000)
   ,constraint utc_testcase_pk primary key (testsuite_name, testsuite_owner, testcase_name)
   --,constraint utc_testcase_fk1 foreign key (testsuite_name, testsuite_owner)
   --    references utc_testsuite (testsuite_name, testsuite_owner)
   ,constraint utc_testcase_ck1 check (status in ('SKIPPED','RUNNING','SUCCESS','FAILURE'))
   )
   on commit preserve rows
   ;

comment on table utc_testcase is 'List of current test cases within test suites';
comment on column utc_testcase.testsuite_name  is 'Test suite name, primary key 1 of 3';
comment on column utc_testcase.testsuite_owner is 'Test suite name, primary key 2 of 3';
comment on column utc_testcase.testcase_name   is 'Test case name, primary key 3 of 3';
comment on column utc_testcase.status          is 'Current status of this test case: SKIPPED, RUNNING, SUCCESS, FAILURE';
comment on column utc_testcase.start_on        is 'Date/time this test case started';
comment on column utc_testcase.end_on          is 'Date/time this test case ended';
comment on column utc_testcase.errors          is 'Errors that occured at the test case level';
