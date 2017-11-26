create or replace package utplsql
AUTHID CURRENT_USER
is

/************************************************************************
GNU General Public License for utPLSQL

Copyright (C) 2000-2003
Steven Feuerstein and the utPLSQL Project
(steven@stevenfeuerstein.com)

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program (see license.txt); if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
************************************************************************
$Log$
Revision 3.0  2106/04/04 Duane Dieterich
Converted to v3

************************************************************************/

   function version
      return varchar2;

   -- Assert Reporting
   procedure report
      (assert_name_in    in  VARCHAR2
      ,test_failed_in    in  BOOLEAN
      ,message_in        in  VARCHAR2
      ,assert_details_in in  VARCHAR2  default ''
      ,errors_in         in  VARCHAR2  default ''
      ,register_in       in  BOOLEAN   default TRUE
      ,showresults_in    in  BOOLEAN   default TRUE);
      -- showeresults_in FALSE will prevent output of an assertion if the
      --   assertion is run standalone.

   -- Testcase Halt on Exceptions
   PROCEDURE haltonexception
      (onoff_in  IN  BOOLEAN);

   -- Main run procedure
   PROCEDURE run
      (package_name_in      IN  VARCHAR2
      ,package_owner_in     IN  VARCHAR2 default user
      ,showresults_in       IN  BOOLEAN  default TRUE
      ,proc_prefix_in       IN  VARCHAR2 default ''
      ,per_method_setup_in  IN  BOOLEAN := FALSE);
      -- showeresults_in FALSE will prevent output at the end
      --   of the Package/TestSuite.

end utplsql;
