
create
   global temporary
   table utc_outcome
   (testsuite_name   VARCHAR2(128)  constraint utc_outcome_nn1 not null
   ,testsuite_owner  VARCHAR2(128)  constraint utc_outcome_nn2 not null
   ,testcase_name    VARCHAR2(128)  constraint utc_outcome_nn3 not null
   ,outcome_seq      NUMBER(6)      constraint utc_outcome_nn4 not null
   ,assert_name      VARCHAR2(128)  constraint utc_outcome_nn5 not null
   ,status           VARCHAR2(8)    constraint utc_outcome_nn6 not null
   ,run_on           TIMESTAMP(9)   constraint utc_outcome_nn7 not null
   ,message          VARCHAR2(4000) constraint utc_outcome_nn8 not null
   ,assert_details   VARCHAR2(4000)
   ,errors           VARCHAR2(4000)
   ,constraint utc_outcome_pk primary key (testsuite_name, testsuite_owner, testcase_name, outcome_seq)
   --,constraint utc_outcome_fk1 foreign key (testsuite_name, testsuite_owner, testcase_name)
   --    references utc_testcase (testsuite_name, testsuite_owner, testcase_name)
   ,constraint utc_outcome_ck1 check (status in ('SUCCESS','FAILURE'))
   )
   on commit preserve rows
   ;

comment on table utc_outcome is 'List of current outcomes within test cases';
comment on column utc_outcome.testsuite_name  is 'Test suite name, primay key 1 of 4';
comment on column utc_outcome.testsuite_owner is 'Test suite owner, primay key 2 of 4';
comment on column utc_outcome.testcase_name   is 'Test case name, primary key 3 of 4';
comment on column utc_outcome.outcome_seq     is 'Outcome sequence, primary key 4 of 4';
comment on column utc_outcome.assert_name     is 'Assertion name';
comment on column utc_outcome.status          is 'Status of this outcome: success, failure';
comment on column utc_outcome.run_on          is 'Date/time this outcome ran';
comment on column utc_outcome.assert_details  is 'Details of this assertion';
comment on column utc_outcome.message         is 'Message provided with this assertion';
comment on column utc_outcome.errors          is 'Errors that occured during this assertion';
