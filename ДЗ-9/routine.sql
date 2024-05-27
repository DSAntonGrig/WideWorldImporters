-- DROP FUNCTION website.searchforstockitems(VARCHAR(1000),INTEGER)

CREATE OR REPLACE FUNCTION website.searchforstockitems(
    IN par_searchtext VARCHAR(1000),
    IN par_maximumrowstoreturn INTEGER
)
    RETURNS TEXT -- FOR JSON AUTO возвращает nvarchar(max)
    SECURITY DEFINER -- WITH EXECUTE AS OWNER
    LANGUAGE plpgsql
AS
$BODY$
DECLARE
    json_text_result TEXT;
BEGIN
    SELECT jsonb_build_object(
                   'StockItems', jsonb_agg(jsonb_build_object(
                    'StockItemID', si.stockitemid,
                    'StockItemName', si.stockitemname
                ))
               )
    INTO json_text_result
    FROM (SELECT si.stockitemid,
                 si.stockitemname
          FROM warehouse.stockitems AS si
          WHERE si.searchdetails ILIKE '%' || par_searchtext || '%' -- Latin1_General_100_CI_AS
          ORDER BY si.stockitemname
          LIMIT par_maximumrowstoreturn) AS si;

    RETURN json_text_result;
    END;
$BODY$;

ALTER FUNCTION website.searchforstockitems(VARCHAR(1000), INTEGER) OWNER TO postgres;