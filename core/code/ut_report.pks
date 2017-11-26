create or replace package utreport
AUTHID CURRENT_USER
as 
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
$Log
Revision 3.0  2106/04/04 Duane Dieterich
Converted to v3

************************************************************************/

   -- Public Constants
   c_skipped        CONSTANT varchar2(8) := 'SKIPPED';
   c_running        CONSTANT varchar2(8) := 'RUNNING';
   c_success        CONSTANT varchar2(8) := 'SUCCESS';
   c_failure        CONSTANT varchar2(8) := 'FAILURE';

   function version
      return varchar2;

   PROCEDURE reset_reporter;

   -- Custom Reporter Setup
   PROCEDURE use_reporter
      (reporter_in IN VARCHAR2
      ,failover_in In BOOLEAN default TRUE);

   PROCEDURE show_result
      (utc_outcome_in  in  utc_outcome%ROWTYPE);

   PROCEDURE run_act_reporter
      (testsuite_rec_in  in  utc_testsuite%ROWTYPE);

end utreport;