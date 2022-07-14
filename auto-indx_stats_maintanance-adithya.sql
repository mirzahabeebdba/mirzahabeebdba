
/****** Object:  StoredProcedure [dbo].[indx_stats_maintanance]    Script Date: 07/18/2014 19:25:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure [dbo].[indx_stats_maintanance]
As
Begin
----------Table to Hold Fragmented Objects---- 
If exists (select * from tempdb.sys.all_objects where name = '#Reorganize' ) 
Drop table #Reorganize 
create table #Reorganize        
(Schemaname varchar(50), 
tablename varchar(50), 
Indexname varchar(150), 
Fragmentation float) 

If exists (select * from tempdb.sys.all_objects where name = '#Rebuild' ) 
drop table #Rebuild 
create table #Rebuild       
(Schemaname varchar(100), 
tablename varchar(100), 
Indexname varchar(150), 
Fragmentation float) 

/*-----------Inserting All fragmented table where fragmentation level is between 5 to 30 in temptable---- 
insert into #reorganize(Schemaname,tablename,Indexname,Fragmentation) 
select s.name,o.name,i.name,ips.avg_fragmentation_in_percent from sys.objects o left outer join sys.schemas s on 
o.schema_id= s.schema_id  left outer join sys.indexes i on 
o.object_id=i.object_id left outer join sys.dm_db_index_physical_stats (db_id(), NULL, NULL, NULL, NULL) AS IPS 
on i.object_id=IPS.object_id and i.index_id=ips.index_id 
where o.type='U' and i.index_id > 0 and avg_fragmentation_in_percent between 5and 30 */

-----------Inserting All fragmented table where fragmentation level is greateer than 30 in temptable---- 

insert into #Rebuild(Schemaname,tablename,Indexname,Fragmentation) 
select s.name,o.name,i.name,ips.avg_fragmentation_in_percent from sys.objects o left outer join sys.schemas s on 
o.schema_id= s.schema_id  left outer join sys.indexes i on 
o.object_id=i.object_id left outer join sys.dm_db_index_physical_stats (db_id(), NULL, NULL, NULL, NULL) AS IPS 
on i.object_id=IPS.object_id and i.index_id=ips.index_id 
where o.type='U' and i.index_id > 0 and avg_fragmentation_in_percent > 30 
  
/*-----------Cursor for reorganize--------------------- 
Declare @cmd varchar(1000) 
DECLARE @ReIname varchar(250) 
DECLARE @ReJname varchar(250) 
declare @Resname varchar(150) 
declare @Retname varchar(150) 
DECLARE db_reindex CURSOR for 
select  indexname,[SCHEMANAME],tablename from #Reorganize 
OPEN db_reindex 
FETCH NEXT from db_reindex into @ReIname,@Resname,@Retname 
WHILE @@FETCH_STATUS = 0 
BEGIN 
set @ReJname= @Resname + '.'+  @Retname 
set @cmd= 'Alter INdex ' + @ReIname + ' on '+ @ReJname + ' reorganize' 
execute (@cmd) 
FETCH NEXT from db_reindex into @Reiname,@Resname,@Retname 
select 'Executed Reindex reorganize for ' + @ReJname + ' '+ @ReIname --1
END 
CLOSE db_reindex 
DEALLOCATE db_reindex */
 
------------Cursor For Rebuild-------------- 
DECLARE @RoIname varchar(250) 
DECLARE @RoJname varchar(250) 
declare @Rosname varchar(150) 
declare @Rotname varchar(150) 
DECLARE db_reindex CURSOR for 
select  indexname,[SCHEMANAME],tablename from #Rebuild 
OPEN db_reindex 
FETCH NEXT from db_reindex into @RoIname,@Rosname,@Rotname 
WHILE @@FETCH_STATUS = 0 
BEGIN 
set @RoJname= @Rosname + '.'+  @Rotname 
set @cmd= 'Alter INdex ' + @RoIname + ' on '+ @RoJname + ' rebuild' +' '+'With (Fillfactor=90)'
execute (@cmd) 
FETCH NEXT from db_reindex into @Roiname,@Rosname,@Rotname 
select 'Executed Reindex rebuild for ' + @RoJname + ' '+ @RoIname --2
END 
CLOSE db_reindex 
DEALLOCATE db_reindex 


--update stats for ERM Database
select distinct o.name into #updatestats from sys.objects o left outer join sys.schemas s on 
o.schema_id= s.schema_id  left outer join sys.indexes i on 
o.object_id=i.object_id left outer join sys.dm_db_index_physical_stats (db_id(), NULL, NULL, NULL, NULL) AS IPS 
on i.object_id=IPS.object_id and i.index_id=ips.index_id 
where o.type='U' order by name 

Declare @tblname varchar(800)
DECLARE db_updatestats CURSOR for 
select  name from #updatestats 
OPEN db_updatestats
fetch next from  db_updatestats into @tblname
while @@Fetch_status=0
Begin
set @cmd='Update statistics'+' '+@tblname+' '+'with Fullscan'
Execute(@cmd)
FETCH NEXT from db_updatestats into @tblname
select 'Executed Update stats for ' + @tblname
End
Close db_updatestats
Deallocate db_updatestats
drop table #updatestats
drop table #reorganize
drop table  #Rebuild
End

