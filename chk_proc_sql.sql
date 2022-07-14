select * from sys.dm_exec_query_stats
go
select * from sys.dm_exec_sql_text(sql_handle)
go
select query_plan from sys.dm_exec_query_plan(plan_handle)
go
