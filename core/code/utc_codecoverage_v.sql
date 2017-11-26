create or replace view utc_codecoverage_v as
select ppd.runid
      ,ppd.unit_number
      ,ppd.line#
      ,ppd.total_occur
      ,ppd.total_time
      ,ppu.unit_owner
      ,ppu.unit_name
      ,ppu.unit_type
      ,src.line
      ,src.text
 from  plsql_profiler_data  ppd
       join plsql_profiler_units ppu
            on (    ppu.unit_number = ppd.unit_number
                and ppu.runid       = ppd.runid       )
       join all_source  src
            on (    src.owner = ppu.unit_owner
                and src.name  = ppu.unit_name
                and src.type  = ppu.unit_type
                and src.line  = ppd.line# + utcodecoverage.trigger_offset
                                                        (ppu.unit_owner
                                                        ,ppu.unit_name
                                                        ,ppu.unit_type) );

comment on table utc_codecoverage_v is 'View of DBMS_PROFILER and ALL_SOURCE data for utPLSQL Code Coverage';
comment on column utc_codecoverage_v.runid       is 'Primary key 1 of 3, Unique run identifier from plsql_profiler_runs';
comment on column utc_codecoverage_v.unit_number is 'Primary key 2 of 3, Internally generated library unit # from plsql_profiler_units';
comment on column utc_codecoverage_v.line#       is 'Primary key 3 of 3, Line number in unit';
comment on column utc_codecoverage_v.total_occur is 'Number of times line was executed';
comment on column utc_codecoverage_v.total_time  is 'Total time spent executing line';
comment on column utc_codecoverage_v.unit_owner  is 'Library unit owner name';
comment on column utc_codecoverage_v.unit_name   is 'Library unit name';
comment on column utc_codecoverage_v.unit_type   is 'Library unit type';
comment on column utc_codecoverage_v.line        is 'Line number of this line of source';
comment on column utc_codecoverage_v.text        is 'Source text';
