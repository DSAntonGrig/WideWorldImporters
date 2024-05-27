/*
Домашнее задание по курсу Миграция на PostgreSQL в OTUS.
Занятие "09 - Хранимые процедуры, функции, триггеры, курсоры отличие в PG".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
- sql server https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak
- pg https://github.com/Azure/azure-postgresql/tree/master/samples/databases/wide-world-importers


Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
*/

-- ---------------------------------------------------------------------------
-- Переписываем хранимые процедуры с T SQL на pl/pgsql
-- ---------------------------------------------------------------------------

/*1. хп из WideWorldImporters - нужно переписать на pl/pgsql */
CREATE PROCEDURE [Website].[SearchForStockItems]
@SearchText nvarchar(1000),
@MaximumRowsToReturn int
WITH EXECUTE AS OWNER
AS
BEGIN
    SELECT TOP(@MaximumRowsToReturn)
           si.StockItemID,
           si.StockItemName
    FROM Warehouse.StockItems AS si
    WHERE si.SearchDetails LIKE N'%' + @SearchText + N'%'
    ORDER BY si.StockItemName
    FOR JSON AUTO, ROOT(N'StockItems');
END;
