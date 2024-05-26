
--Таблица объема поставок фруктов в разрезе поставщиков и лет
CREATE TEMP TABLE temp_harvesting_fruits
(
    company_id INT,
    apple      INT,
    grape      INT,
    year       INT
);

--Таблица компаний
CREATE TEMP TABLE temp_company
(
    id   INT PRIMARY KEY,
    name VARCHAR(45)
);

INSERT INTO temp_harvesting_fruits
VALUES (1, 1000, 2000, 2015)
     , (1, 5000, 3000, 2016)
     , (1, 5000, 3000, 2017)
     , (1, 5000, 3000, 2018)
     , (2, 9995, 8880, 2015)
     , (2, 9990, 8880, 2016)
     , (2, 9990, 6660, 2017)
     , (2, 9990, 5550, 2018)
     , (3, 3995, 3880, 2015)
     , (3, 3990, 4880, 2016)
     , (3, 3990, 5660, 2017)
     , (3, 3990, 6550, 2018);

INSERT INTO temp_company
VALUES (1, 'FGS')
     , (2, 'Village')
     , (3, 'Best Fruit');

--Имеем сводный набор данных:
SELECT *
FROM temp_harvesting_fruits AS f
         INNER JOIN temp_company AS c ON (c.id = f.company_id);

--LATERAL
--Сначала собираем табличку в разрезе компаний и при этом объединим названия фруктов с годом:
SELECT c.name, fruits_by_year.*
FROM temp_harvesting_fruits AS fruits
         INNER JOIN temp_company AS c ON (fruits.company_id = c.id)
         INNER JOIN LATERAL (VALUES (CONCAT('APPLES - ', fruits.year), fruits.apple),
                                    (CONCAT('GRAPES - ', fruits.year), fruits.grape)
    ) AS fruits_by_year (fruit_year, amount) ON TRUE;

--CROSSTAB - группируем и разворачиваем только за три выбранных года
SELECT *
FROM CROSSTAB($$SELECT с.name, fruits_by_year.fruit_year, fruits_by_year.amount
                FROM temp_harvesting_fruits AS fruits
                INNER JOIN temp_company AS с ON (fruits.company_id = с.id)
                INNER JOIN LATERAL (VALUES (CONCAT('APPLES - ', fruits.year), fruits.apple),
                                           (CONCAT('GRAPES - ', fruits.year), fruits.grape)
                ) AS fruits_by_year (fruit_year, amount) ON TRUE
                ORDER BY 1, 2$$,
              $$SELECT DISTINCT fruits_by_year.fruit_year
                FROM temp_harvesting_fruits AS fruits
                INNER JOIN LATERAL (VALUES (CONCAT('APPLES - ', fruits.year), fruits.apple),
                                           (CONCAT('GRAPES - ', fruits.year), fruits.grape)
                ) AS fruits_by_year (fruit_year, amount) ON TRUE
                WHERE fruits.year IN (2015, 2016, 2017)
                ORDER BY 1$$)
         AS cts (
                 name VARCHAR(45),
                 "APPLES - 2015" INT,
                 "APPLES - 2016" INT,
                 "APPLES - 2017" INT,
                 "GRAPES - 2015" INT,
                 "GRAPES - 2016" INT,
                 "GRAPES - 2017" INT
        );

DROP TABLE temp_harvesting_fruits;
DROP TABLE temp_company;
