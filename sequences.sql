-- Подготавливаем скрипты в MS SQL. Запускаем в PostgreSQL

-- Формируем скрипты для создания последовательностей

SELECT 
    'CREATE SEQUENCE ' + LOWER(s.name) + '.' + LOWER(seq.name) + CHAR(13) + CHAR(10) +
	'AS ' + UPPER(t.name) + CHAR(13) + CHAR(10) +
    'START WITH ' + CAST(seq.start_value AS VARCHAR(50)) + CHAR(13) + CHAR(10) +
    'INCREMENT BY ' + CAST(seq.increment AS VARCHAR(50)) + CHAR(13) + CHAR(10) +
    CASE WHEN seq.minimum_value IS NOT NULL THEN 'MINVALUE ' + CAST(seq.minimum_value AS VARCHAR) ELSE '' END + CHAR(13) + CHAR(10) +
    CASE WHEN seq.maximum_value IS NOT NULL THEN 'MAXVALUE ' + CAST(seq.maximum_value AS VARCHAR) ELSE '' END + CHAR(13) + CHAR(10) +
    CASE WHEN seq.is_cached = 1 THEN CONCAT('CACHE ',Convert(VARCHAR,COALESCE(seq.cache_size,1))) ELSE 'NO CACHE' END + CHAR(13) + CHAR(10) +
    CASE WHEN seq.is_cycling = 1 THEN 'CYCLE' ELSE 'NO CYCLE' END +';' + CHAR(13) + CHAR(10)
FROM sys.sequences seq INNER JOIN sys.schemas s ON seq.schema_id = s.schema_id
					   INNER JOIN sys.types t ON (seq.user_type_id = t.user_type_id And
												  seq.system_type_id = t.system_type_id)
ORDER BY s.[name], seq.[name]

-- Формируем скрипты для создания значений по умолчанию

SELECT CONCAT('ALTER TABLE ', LOWER(h.[name]), '.', LOWER(t.[name]), ' ALTER COLUMN ', LOWER(c.[name]), ' SET DEFAULT ', 
	   CASE WHEN dc.[definition] = '(sysdatetime())' THEN 'localtimestamp;'
		    WHEN dc.[definition] LIKE '%(NEXT VALUE FOR \[Sequences\].\[%\])' ESCAPE '\' THEN CONCAT(LOWER(REPLACE(REPLACE(REPLACE(REPLACE(dc.[definition], '(NEXT VALUE FOR [Sequences].','nextval(''sequences.'),'[',''),']',''),')',''')')),';')
	   END)
FROM sys.default_constraints dc INNER JOIN sys.columns c ON (dc.parent_object_id = c.object_id And
															 dc.parent_column_id = c.column_id)
								INNER JOIN sys.tables t ON (t.object_id = c.object_id)
								INNER JOIN sys.schemas h ON (t.schema_id = h.schema_id)
								INNER JOIN sys.types s ON (c.system_type_id=s.system_type_id)
ORDER BY h.[name], t.[name], c.[name]


