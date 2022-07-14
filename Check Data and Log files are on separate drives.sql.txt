select 
DB_NAME(mf.database_id) as [db_name], 
checkDBLocation = CASE WHEN ( 
select count(*) from sys.master_files as m1  
where  m1.type_desc IN ('LOG')  and mf.type_desc IN ('ROWS') 
AND substring(m1.physical_name,1,1) = substring(mf.physical_name,1,1) 
AND m1.database_id = mf.database_id 
) > 0 THEN '1' 
ELSE '0' 
END, 
substring(physical_name,1,1)  as 'Drive letter'
from sys.master_files as mf


--In the situation of MOUNTED DRIVES where you might have
--d:\data , d:\logs , d:\temp 
--this version will compare the drive letter and upto the second "\"

select 
DB_NAME(mf.database_id) as [db_name], 
checkDBLocation = CASE WHEN ( 
select count(*) from sys.master_files as m1  
where  m1.type_desc IN ('LOG')  and mf.type_desc IN ('ROWS') 
AND SUBSTRING(m1.physical_name,1,CHARINDEX('\',m1.physical_name,4)) = SUBSTRING(mf.physical_name,1,CHARINDEX('\',m1.physical_name,4))
AND m1.database_id = mf.database_id 
) > 0 THEN '1' 
ELSE '0' 
END, 
substring(physical_name,1,1)  as 'Drive letter'
from sys.master_files as mf
