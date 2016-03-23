create or replace PACKAGE ut_betwnstr
AUTHID CURRENT_USER
IS

   PROCEDURE utplsql_init;  -- No prefix

   PROCEDURE ut_setup;
   PROCEDURE ut_teardown;
   
   -- For each program to test...
   PROCEDURE ut_betwnstr;
   PROCEDURE ut_throw_error;

END ut_betwnstr;