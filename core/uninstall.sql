
-- Quick UnInstall - Prototype for example purposes only
--    Not responsible for damage to database or system

-- Connect to the database using the "system" account

spool uninstall

-- Run as SYSTEM
prompt Dropping user UTC, Press Enter to Continue
accept junk
DROP USER UTC CASCADE;

prompt Run @code/drop_public.sql to remove public synonyms

spool off
