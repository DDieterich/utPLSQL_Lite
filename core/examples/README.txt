
README for EXAMPLE Directory

Files in this directory:
------------------------
betwnstr.fnc      - Example database object under test (DOUT).  Run as UTC
run_test.sql      - Example unit test package execution.        Run as UTC
ut_betwnstr.pkb   - Example unit test package body.             Run as UTC
ut_betwnstr.pks   - Example unit test package specification.    Run as UTC

---------------------------------
Example sequences run in SQL*Plus
---------------------------------

Example Installation and Run Sequence:
--------------------------------------
login UTC/UTC
@betwnstr.fnc
@ut_betwnstr.pks
@ut_betwnstr.pkb
@run_test.sql

Example Removal Sequence:
-------------------------
login as UTC/UTC
DROP PACKAGE UT_BETWNSTR;
DROP FUNCTION BETWNSTR;
