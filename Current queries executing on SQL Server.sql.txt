SELECT 
r.session_id,
s.TEXT,
r.[status],
r.blocking_session_id,
r.cpu_time,
r.total_elapsed_time
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS s 
