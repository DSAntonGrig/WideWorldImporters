-- 'Cities','Countries','StateProvinces','SystemParameters' in schema 'Application'
-- 'Suppliers' in schema 'Purchasing'
-- 'Customers' in schema 'Sales'

-- Создаем представления в MS SQL

DECLARE @QueryText nVarChar(max);

DECLARE CUR CURSOR FAST_FORWARD FOR
SELECT CONCAT('CREATE VIEW ', h.name, '.', t.name, '_$view AS') + CHAR(13) + CHAR(10) +
	   CONCAT('SELECT ', STRING_AGG(CONCAT(c.name, CASE WHEN s.name = 'geography' THEN CONCAT('.STAsText() AS ', c.name) END), ',') WITHIN GROUP (ORDER BY column_id)) + CHAR(13) + CHAR(10) +
	   CONCAT('FROM ', h.name, '.', t.name, ';') + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) AS QueryText
FROM sys.tables AS t INNER JOIN sys.schemas AS h ON (t.schema_id=h.schema_id)
					 INNER JOIN sys.columns AS c ON (t.object_id=c.object_id)
					 INNER JOIN sys.types AS s ON (c.user_type_id=s.user_type_id)
					 CROSS APPLY (SELECT DISTINCT c.object_id
							      FROM sys.columns AS c INNER JOIN sys.types AS s ON (c.user_type_id=s.user_type_id)
								  WHERE t.object_id=c.object_id
								    AND s.name = 'geography'
								  ) AS y
WHERE t.name NOT LIKE '%[_]ARCHIVE%'
GROUP BY h.name, t.name;

OPEN CUR;
FETCH NEXT FROM CUR INTO @QueryText;
WHILE 0=0 
	BEGIN
		IF @@FETCH_STATUS<>0 BREAK;
		PRINT @QueryText;
		EXECUTE sp_executesql @QueryText;
		FETCH NEXT FROM CUR INTO @QueryText;
	END;

CLOSE CUR;
DEALLOCATE CUR;

-- Формируем скрипты в MS SQL выполняем в PostgreSQL

-- Создание FDT

SELECT CONCAT('IMPORT FOREIGN SCHEMA',' "',s.name,'" LIMIT TO (', STRING_AGG(CONCAT('"',v.name,'"'),','),')') + CHAR(13) + CHAR(10) +
	   CONCAT('FROM SERVER ms_wwi INTO ', LOWER(s.name), ';')
FROM sys.views AS v INNER JOIN sys.schemas AS s ON (v.schema_id=s.schema_id)
WHERE v.name LIKE '%[_]$view'
GROUP BY s.name;

-- Вставка данных в таблицы с типом geography из FDT

SELECT CONCAT('INSERT INTO ', LOWER(h.name), '.', LOWER(t.name), '(', STRING_AGG(c.name,',') WITHIN GROUP (ORDER BY column_id), ')') + CHAR(13) + CHAR(10) +
	   CONCAT('SELECT ', STRING_AGG(CONCAT('"',c.name,'"', CASE WHEN s.name = 'geography' THEN '::geography' WHEN s.name = 'bit' THEN '::varchar::boolean' END), ',') WITHIN GROUP (ORDER BY column_id)) + CHAR(13) + CHAR(10) +
	   CONCAT('FROM ', LOWER(h.name), '."', t.name,'_$view";')
FROM sys.tables AS t INNER JOIN sys.schemas AS h ON (t.schema_id=h.schema_id)
					 INNER JOIN sys.columns AS c ON (t.object_id=c.object_id)
					 INNER JOIN sys.types AS s ON (c.user_type_id=s.user_type_id)
					 CROSS APPLY (SELECT DISTINCT c.object_id
							      FROM sys.columns AS c INNER JOIN sys.types AS s ON (c.user_type_id=s.user_type_id)
								  WHERE t.object_id=c.object_id
								    AND s.name = 'geography'
								  ) AS y
WHERE t.name NOT LIKE '%[_]ARCHIVE%'
GROUP BY h.name, t.name
ORDER BY h.name, t.name;
