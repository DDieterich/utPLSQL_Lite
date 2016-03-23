
README for Core Directory


Files in this directory:
------------------------
code          - Directory of source code
docs          - Directory of documentation
examples      - Directory of examples
test          - Directory of unit tests
install.LST   - Sample results from a quick install
install.sql   - Quick install script
run_test.LST  - Sample results from the example test
uninstall.LST - Sample results from a quick uninstall
uninstall.sql - Quick uninstall script

---------------------------------
Example sequences run in SQL*Plus
---------------------------------

Quick Install:
--------------
sqlplus system @install.sql


Quick Test Example:
-------------------
sqlplus utc/utc @examples/run_test.sql


Quick Uninstall:
----------------
sqlplus system @uinstall.sql
