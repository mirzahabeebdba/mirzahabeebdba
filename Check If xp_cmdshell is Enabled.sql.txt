Check If xp_cmdshell is Enabled 

SELECT CONVERT(INT, ISNULL(value, value_in_use)) AS config_value
FROM  sys.configurations
WHERE  name = N'xp_cmdshell' ;

