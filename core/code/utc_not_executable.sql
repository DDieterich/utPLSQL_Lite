
--  Create table to exclude non-executable lines from code coverage
create table utc_not_executable
   (text  varchar2(4000)
   ,note  varchar2(4000)
   ,constraint utc_not_executable_pk primary key (text)
   );

comment on table utc_not_executable is 'Table to exclude non-executable lines from code coverage';
comment on column utc_not_executable.text is 'Primary key, source text to exclude from code coverage';
comment on column utc_not_executable.note is 'Notes regarding this non-exectuable line of code';
