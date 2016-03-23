
README for CODE directory (SQL Source)

Files in this directory:
------------------------
create_owner.sql       - Creates schema owner UTC.            Run as SYSTEM.
create_proftab.sql     - DBMS_PROFILER tables.      Called by create_schema.sql
create_public.sql      - Create public synonyms and grants.   Run as SYSTEM.
create_schema.sql      - Master install script.               Run as UTC
drop_proftab.sql       - Drop DBMS_PROFILER tables. Called by drop_schema.sql
drop_public.sql        - Removes public synonyms and grants.  Run as SYSTEM.
drop_schema.sql        - Master uninstall script.             Run as UTC
ut_assert.pkb          - Package body script.       Called by create_schema.sql
ut_assert.pks          - Package body script.       Called by create_schema.sql
ut_codecoverage.pkb    - Package body script.       Called by create_schema.sql
ut_codecoverage.pks    - Package spec script.       Called by create_schema.sql
ut_outputreporter.pkb  - Package body script.       Called by create_schema.sql
ut_outputreporter.pks  - Package spec script.       Called by create_schema.sql
ut_plsql.pkb           - Package body script.       Called by create_schema.sql
ut_plsql.pks           - Package spec script.       Called by create_schema.sql
ut_report.pkb          - Package body script.       Called by create_schema.sql
ut_report.pks          - Package spec script.       Called by create_schema.sql
utc_codecoverage_v.sql - View script.               Called by create_schema.sql
utc_not_executable.sql - Table script.              Called by create_schema.sql
utc_outcome.sql        - Table script.              Called by create_schema.sql
utc_testcase.sql       - Table script.              Called by create_schema.sql
utc_testsuite.sql      - Table script.              Called by create_schema.sql

---------------------------------
Example sequences run in SQL*Plus
---------------------------------

Example Installation Sequence:
------------------------------
login SYSTEM
@create_owner.sql
login UTC/UTC
@create_schema.sql
login SYSTEM
@create_public.sql

Example Removal Sequence:
-------------------------
login SYSTEM
@drop_public.sql
DROP USER UTC CASCADE;
