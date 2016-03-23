
-- This is unfinished, a place holder for more rigorous installation scripts

-- USER
create user utc identified by utc 
   default tablespace users
   temporary tablespace temp;

grant connect, resource to utc;
grant create view to utc;
