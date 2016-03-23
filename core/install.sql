
-- Quick Install - Prototype for example purposes only
--    Not responsible for damage to database or system

-- Connect to the database using the "system" account

spool install
set define '&'

-- Run as SYSTEM

@code/create_owner.sql

alter session set current_schema = utc;

-- Run as UTC

@code/create_schema.sql

@examples/betwnstr.fnc
/
@examples/ut_betwnstr.pks
/
@examples/ut_betwnstr.pkb
/

-- Back to SYSTEM

alter session set current_schema = system;

prompt Optionally run @code/create_public.sql as system
prompt Run @examples/run_test.sql as UTC to see example

spool off
