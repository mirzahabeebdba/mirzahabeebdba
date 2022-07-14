SELECT * FROM dbo.sysprocessesWHERE blocked <> 0;
SELECT * FROM dbo.sysprocesses WHERE spid IN (SELECT blocked FROM dbo.sysprocesses where blocked <> 0);
