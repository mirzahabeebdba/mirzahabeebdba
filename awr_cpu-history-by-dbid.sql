set echo off feedback off timing off pause off verify off
set pagesize 500 linesize 90 trimout on trimspool on
col inst_id format 90 heading "Inst"
col begin_tm format a12 heading "Begin Time"
col end_tm format a12 heading "End Time"
col ela_secs format 999,999,990 heading "Wall-Clock|Secs|Elapsed"
col cpu_ela_secs format 999,999,990 heading "CPU Secs|Elapsed|(Secs*CPUs)"
col used_secs format 999,999,990 heading "CPU Secs|Used"
col pct format 99,990.00 heading "% Used"
col arrow format a5 heading "When?"
col name new_value V_DBNAME noprint

define V_PCT_THRESHOLD="40"

select name from v$database;
clear breaks computes
break on inst_id skip 1
compute max of pct on inst_id
--ttitle center '&&V_DBNAME - CPU Utilization by instance - daily summary' skip line

select	inst_id,
	begin_tm,
	ela_secs,
	cpu_ela_secs,
	used_secs,
	pct,
	decode(greatest(this_pct,&&V_PCT_THRESHOLD),this_pct,'<==','') arrow
from	(select	inst_id,
		to_char(to_date(begin_tm,'DD-MON HH24:MI'), 'DD-MON') begin_tm,
		sum(ela_secs) ela_secs,
		sum(cpu_ela_secs) cpu_ela_secs,
		sum(used_secs) used_secs,
		(sum(used_secs)/sum(cpu_ela_secs))*100 pct,
		max(nvl(this_pct,0)) this_pct,
		max_pct
	 from	(select	inst_id,
			begin_tm,
			end_tm,
			ela_secs,
			cpu_ela_secs,
			sum(used_secs) used_secs,
			sum(pct) this_pct,
			max(sum(pct)) over () max_pct
		 from	(select	stm.instance_number inst_id,
				to_char(s.begin_interval_time,'DD-MON HH24:MI') begin_tm,
				to_char(s.end_interval_time,'DD-MON HH24:MI') end_tm,
				(to_date(to_char(s.end_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS')
				 - to_date(to_char(s.begin_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS'))*86400 ela_secs,
				((to_date(to_char(s.end_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS')
				  - to_date(to_char(s.begin_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS'))*86400)*
					p.value cpu_ela_secs,
				decode(greatest(stm.value, lag(stm.value,1,999999999999999999)
							   over (partition by	stm.dbid,
										stm.instance_number,
										stm.stat_name
								 order by	stm.snap_id)),
					999999999999999999, 0,
					stm.value, ((stm.value - lag(stm.value,1,null)
								 over (partition by	stm.dbid,
											stm.instance_number,
											stm.stat_name
									order by	stm.snap_id))/1000000),
					stm.value/1000000) used_secs,
				(decode(greatest(stm.value, lag(stm.value,1,999999999999999999)
							    over (partition by	stm.dbid,
										stm.instance_number,
										stm.stat_name
								  order by	stm.snap_id)),
					999999999999999999, 0,
					stm.value, ((stm.value - lag(stm.value,1,null)
								 over (partition by	stm.dbid,
											stm.instance_number,
											stm.stat_name
									order by	stm.snap_id))/1000000),
					stm.value/1000000) /
				 (((to_date(to_char(s.end_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS')
				    - to_date(to_char(s.begin_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS'))*86400)*p.value))
					*100 pct
			 from	dba_hist_sys_time_model stm,
				dba_hist_snapshot s,
				gv$parameter p,
                                dbsnmp.caw_dbid_mapping m
			 where	stm.stat_name in ('DB CPU','background cpu time')
                         and    LOWER(m.target_name)= '&dbname'
                         and    s.dbid= m.new_dbid
			 and	s.snap_id = stm.snap_id
			 and	s.dbid = stm.dbid
			 and	s.instance_number = stm.instance_number
			 and	p.name = 'cpu_count'
			 and	p.inst_id = s.instance_number)
		 group by inst_id,
			  begin_tm,
			  end_tm,
			  ela_secs,
			  cpu_ela_secs)
	 group by inst_id,
		  to_char(to_date(begin_tm,'DD-MON HH24:MI'), 'DD-MON'),
		  max_pct)
/*
where	max_pct >= &&V_PCT_THRESHOLD
*/
order by inst_id,
	 begin_tm;

ttitle center '&&V_DBNAME - CPU Utilization by instance - AWR snapshot detail' skip line
select	inst_id,
	begin_tm,
	end_tm,
	ela_secs,
	cpu_ela_secs,
	used_secs,
	pct,
	decode(greatest(&&V_PCT_THRESHOLD,nvl(pct,0)),pct,'<==','') 
from	(select	inst_id,
		begin_tm,
		end_tm,
		ela_secs,
		cpu_ela_secs,
		sum(used_secs) used_secs,
		sum(pct) pct,
		max(sum(pct)) over () max_pct
	 from	(select	stm.instance_number inst_id,
			to_char(s.begin_interval_time,'DD-MON HH24:MI') begin_tm,
			to_char(s.end_interval_time,'DD-MON HH24:MI') end_tm,
			(to_date(to_char(s.end_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS')
			 - to_date(to_char(s.begin_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS'))*86400 ela_secs,
			((to_date(to_char(s.end_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS')
			  - to_date(to_char(s.begin_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS'))*86400)*
				p.value cpu_ela_secs,
			decode(greatest(stm.value, lag(stm.value,1,999999999999999999)
						   over (partition by stm.dbid, stm.instance_number, stm.stat_name
							 order by stm.snap_id)),
				999999999999999999, to_number(null),
				stm.value, ((stm.value - lag(stm.value,1,null)
							 over (partition by stm.dbid, stm.instance_number, stm.stat_name
								order by stm.snap_id))/1000000),
				stm.value/1000000) used_secs,
			(decode(greatest(stm.value, lag(stm.value,1,999999999999999999)
						    over (partition by stm.dbid, stm.instance_number, stm.stat_name
							  order by stm.snap_id)),
				999999999999999999, to_number(null),
				stm.value, ((stm.value - lag(stm.value,1,null)
							 over (partition by stm.dbid, stm.instance_number, stm.stat_name
								order by stm.snap_id))/1000000),
				stm.value/1000000) /
			 (((to_date(to_char(s.end_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS')
			    - to_date(to_char(s.begin_interval_time,'YYYYMMDDHH24MISS'), 'YYYYMMDDHH24MISS'))*86400)*p.value))
				*100 pct
		 from	dba_hist_sys_time_model stm,
			dba_hist_snapshot s,
			gv$parameter p,
                        dbsnmp.CAW_DBID_MAPPING m
		 where	stm.stat_name in ('DB CPU','background cpu time')
                 and    LOWER(m.target_name)= '&&dbname'
                 and    s.dbid=m.new_dbid
		 and	s.snap_id = stm.snap_id
		 and	s.dbid = stm.dbid
		 and	s.instance_number = stm.instance_number
		 and	p.name = 'cpu_count'
		 and	p.inst_id = s.instance_number)
	 group by inst_id,
		  begin_tm,
		  end_tm,
		  ela_secs,
		  cpu_ela_secs)
/*
where	max_pct >= &&V_PCT_THRESHOLD
*/
order by inst_id,
	 begin_tm;

clear breaks computes
set feedback 6 pagesize 100 linesize 130 verify on
ttitle off
