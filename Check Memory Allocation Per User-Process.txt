
--Check Memory Allocation Per User/Process

SET PAGESIZE 9999

COLUMN sid FORMAT 999 HEADING 'SID'

COLUMN oracle_username FORMAT a12 HEADING 'Oracle User' JUSTIFY right

COLUMN os_username FORMAT a9 HEADING 'O/S User' JUSTIFY right

COLUMN session_program FORMAT a18 HEADING 'Session Program' TRUNC

COLUMN session_machine FORMAT a8 HEADING 'Machine' JUSTIFY right TRUNC

COLUMN session_pga_memory FORMAT 9,999,999,999 HEADING 'PGA Memory'

COLUMN session_pga_memory_max FORMAT 9,999,999,999 HEADING 'PGA Memory Max'

COLUMN session_uga_memory FORMAT 9,999,999,999 HEADING 'UGA Memory'

COLUMN session_uga_memory_max FORMAT 9,999,999,999 HEADING 'UGA Memory MAX'

SELECT

s.sid sid

, lpad(s.username,12) oracle_username

, lpad(s.osuser,9) os_username

, s.program session_program

, lpad(s.machine,8) session_machine

, (select round(sum(ss.value/1024/1024)) from v$sesstat ss, v$statname sn

where ss.sid = s.sid and

sn.statistic# = ss.statistic# and

sn.name = 'session pga memory') session_pga_memory

, (select round(sum(ss.value/1024/1024)) from v$sesstat ss, v$statname sn

where ss.sid = s.sid and

sn.statistic# = ss.statistic# and

sn.name = 'session pga memory max') session_pga_memory_max

, (select round(sum(ss.value/1024/1024)) from v$sesstat ss, v$statname sn

where ss.sid = s.sid and

sn.statistic# = ss.statistic# and

sn.name = 'session uga memory') session_uga_memory

, (select round(sum(ss.value/1024/1024)) from v$sesstat ss, v$statname sn

where ss.sid = s.sid and

sn.statistic# = ss.statistic# and

sn.name = 'session uga memory max') session_uga_memory_max

FROM

v$session s

ORDER BY session_pga_memory DESC

/


