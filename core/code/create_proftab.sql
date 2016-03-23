
--  Create tables for the PL/SQL profiler
--    From Oracle XE Release 11.2.0.2.0 Production on Tue Feb 16 04:02:48 2016
--  Must be updated from ORACLE_HOME/rdbms/admin/proftab.sql

create
   global temporary
   table plsql_profiler_runs
   (runid           number  constraint plsql_profiler_runs_nn1 not null
   ,related_run     number
   ,run_owner       varchar2(32)
   ,run_date        date
   ,run_comment     varchar2(2047)
   ,run_total_time  number
   ,run_system_info varchar2(2047)
   ,run_comment1    varchar2(2047)
   ,spare1          varchar2(256)
   ,constraint plsql_profiler_runs_pk primary key (runid)
   )
   on commit preserve rows
   ;

comment on table plsql_profiler_runs is 'Run-specific information for the PL/SQL profiler';
comment on column plsql_profiler_runs.runid           is 'primary key, unique run identifier from plsql_profiler_runnumber';
comment on column plsql_profiler_runs.related_run     is 'runid of related run (for client/server correlation)';
comment on column plsql_profiler_runs.run_owner       is 'user who started run';
comment on column plsql_profiler_runs.run_date        is 'start time of run';
comment on column plsql_profiler_runs.run_comment     is 'user provided comment for this run';
comment on column plsql_profiler_runs.run_total_time  is 'elapsed time for this run in nanoseconds';
comment on column plsql_profiler_runs.run_system_info is 'currently unused';
comment on column plsql_profiler_runs.run_comment1    is 'additional comment';
comment on column plsql_profiler_runs.spare1          is 'unused';

create
   global temporary
   table plsql_profiler_units
   (runid              number             constraint plsql_profiler_units_nn1 not null
   ,unit_number        number             constraint plsql_profiler_units_nn2 not null
   ,unit_type          varchar2(32)
   ,unit_owner         varchar2(32)
   ,unit_name          varchar2(32)
   ,unit_timestamp     date
   ,total_time         number   DEFAULT 0 constraint plsql_profiler_units_nn3 not null
   ,spare1             number
   ,spare2             number
   ,constraint plsql_profiler_units_pk primary key (runid, unit_number)
   --,constraint plsql_profiler_units_fk1 foreign key (runid)
   --    references plsql_profiler_runs (runid)
   )
   on commit preserve rows
   ;

comment on table plsql_profiler_units is 'Information about each library unit in a run';
comment on column plsql_profiler_units.runid             is 'primary key 1 of 2, unique run identifier from plsql_profiler_runs';
comment on column plsql_profiler_units.unit_number       is 'primary key 1 of 2, internally generated library unit #';
comment on column plsql_profiler_units.unit_type         is 'library unit type';
comment on column plsql_profiler_units.unit_owner        is 'library unit owner name';
comment on column plsql_profiler_units.unit_name         is 'library unit name';
comment on column plsql_profiler_units.unit_timestamp    is 'timestamp on library unit, can be used to detect changes to unit between runs';
comment on column plsql_profiler_units.total_time        is 'Total time spent in this unit in nanoseconds. The profiler does not set this field, but it is provided for the convenience of analysis tools';
comment on column plsql_profiler_units.spare1            is 'unused';
comment on column plsql_profiler_units.spare2            is 'unused';

create
   global temporary
   table plsql_profiler_data
   (runid           number  constraint plsql_profiler_data_nn1 not null
   ,unit_number     number  constraint plsql_profiler_data_nn2 not null
   ,line#           number  constraint plsql_profiler_data_nn3 not null
   ,total_occur     number
   ,total_time      number
   ,min_time        number
   ,max_time        number
   ,spare1          number
   ,spare2          number
   ,spare3          number
   ,spare4          number
   ,constraint plsql_profiler_data_pk primary key (runid, unit_number, line#)
   --,constraint plsql_profiler_data_fk1 foreign key (runid, unit_number)
   --    references plsql_profiler_units (runid, unit_number)
   )
   on commit preserve rows
   ;

comment on table plsql_profiler_data is 'Accumulated data from all profiler runs';
comment on column plsql_profiler_data.runid       is 'primary key 1 of 3, unique run identifier from plsql_profiler_runs';
comment on column plsql_profiler_data.unit_number is 'primary key 2 of 3, internally generated library unit # from plsql_profiler_units';
comment on column plsql_profiler_data.line#       is 'primary key 3 of 3, line number in unit';
comment on column plsql_profiler_data.total_occur is 'number of times line was executed';
comment on column plsql_profiler_data.total_time  is 'total time spent executing line';
comment on column plsql_profiler_data.min_time    is 'minimum execution time for this line';
comment on column plsql_profiler_data.max_time    is 'maximum execution time for this line';
comment on column plsql_profiler_data.spare1      is 'unused';
comment on column plsql_profiler_data.spare2      is 'unused';
comment on column plsql_profiler_data.spare3      is 'unused';
comment on column plsql_profiler_data.spare4      is 'unused';

create sequence plsql_profiler_runnumber start with 1 nocache;

