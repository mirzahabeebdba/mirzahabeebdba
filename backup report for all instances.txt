In some of the production environment, we may pass over to configure the transactional log backup even when the database recovery model is Full. This query helps you in identifying the database recovery model, last successful tlog backup datetime, log file size, status (such as "Success", "Failed!!", and "NA"). By default, I set parameter "@check" to 12 hour. If transactional log backup executed successfully in the last 12 hours, then status will be shown as "Success" else it will display as "Failed".

----
SET NOCOUNT ON
declare @check int
set @check= 12
declare @hl int
declare @servername nvarchar(60)
declare @dbname nvarchar(60)
declare @lastTlogBackup datetime

declare @NoTLogSince int
declare @Recovery nvarchar(20)
declare @TlogBkpStatus nvarchar(30)

DECLARE @serverVersion varchar(50)
select @serverVersion = CONVERT(varchar(50),SERVERPROPERTY('ProductVersion'))
SET @serverVersion = LEFT(@serverVersion, CHARINDEX('.', @serverVersion) - 1)

DECLARE @table1 table (Servername nvarchar(60),  DBName nvarchar(60),lastTlogBackup datetime, 
[Recovery] varchar(20),NoTLogSince int,TlogBkpStatus nvarchar(30))

declare c1 cursor for Select Distinct convert(varchar(60),@@Servername) as Servername,
convert(varchar(60),e.database_name) as DBname, (Select convert(varchar(25),
Max(backup_finish_date) , 100) From msdb..backupset c Where c.database_name=e.database_name 
and c.server_name  = @@servername and type='L' Group by c.database_name) 
Last_Tlog_Backup, convert(varchar(20),convert(sysname,
DatabasePropertyEx (e.database_name,'Recovery'))) as Recovery,
NULL AS NoTLogSince,NULL as TlogBkpStatus FROM msdb..backupset e

WHERE e.server_name = @@Servername  and e.database_name not in ('tempdb') 
and e.database_name in (Select Distinct name from master..sysdatabases 
where dbid not in (1,2,3))

Union all select Distinct convert(varchar(60),@@Servername) as Servername,
 convert(varchar(60),name) as DBname,NULL,
convert(varchar(20),convert(sysname,DatabasePropertyEx(name,'Recovery'))),
NULL,NULL from master..sysdatabases as record
where name not in (select distinct database_name from msdb..backupset) 
and dbid not in (1,2,3) order by 1,2

OPEN c1 

FETCH NEXT FROM c1 INTO @servername,@dbname,@lastTlogBackup,@Recovery,
@NoTLogSince, @TlogBkpStatus

WHILE @@FETCH_STATUS=0

BEGIN 

IF (@lastTlogBackup IS NULL)
BEGIN 
set @lastTlogBackup='1900-01-01 00:00:00.000'

END

select @NoTLogSince=datediff(hour,@lastTlogBackup,GETDATE())

INSERT INTO @table1 values (@servername,@dbname,@lastTlogBackup,@Recovery,@NoTLogSince,
@TlogBkpStatus)

UPDATE @table1 SET TlogBkpStatus=CASE

              WHEN NoTLogSince<=@check THEN 'Success'
              WHEN NoTLogSince>=@check THEN 'Failed, Action required !!!!'

END

UPDATE @table1 SET TlogBkpStatus ='NA' where [Recovery]='SIMPLE' OR DBName='model'

FETCH NEXT FROM c1 INTO @servername,@dbname,@lastTlogBackup,@Recovery, 
@NoTLogSince,@TlogBkpStatus

END

IF  convert(int,@serverVersion)>=9  
BEGIN

SELECT ServerName as 'SQLInstanceName',DBName as 'DatabaseName',
(mf.size*8)/1024 as LogFileSize_inMB,LastTlogBackup ,[Recovery] ,
[NoTLogSince] as [NoTLogSince_Hrs],TlogBkpStatus
FROM @table1 tv inner join master.sys.master_files mf
on tv.DBName=(select db_name(mf.database_id))
where mf.type_desc='LOG' and mf.file_id=2 order by   NoTLogSince desc

END

IF convert(int,@serverVersion)<9  
BEGIN

SELECT ServerName as 'SQLInstanceName',DBName as 'DatabaseName',
(mf.size*8)/1024 as LogFileSize_inMB,LastTlogBackup ,[Recovery] ,
[NoTLogSince] as [NoTLogSince_Hrs],TlogBkpStatus FROM @table1 tv 
inner join master..sysaltfiles mf on tv.DBName=(select db_name(mf.dbid))
where  mf.fileid=2 order by  NoTLogSince desc

END

CLOSE c1
DEALLOCATE c1