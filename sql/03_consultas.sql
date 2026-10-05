-- =====================================================================
-- 03_consultas.sql — Consultas para revisar el modelo y calcular KPIs
-- =====================================================================
-- Cada SELECT de este archivo se muestra en la terminal al ejecutar
-- run_sql.py. Usalo para:
--   * comprobar que las tablas se cargaron bien (cantidad de filas, nulos...)
--   * escribir las consultas clave de los KPIs que pide la consigna
--     (ventas, usuarios activos, ticket promedio, NPS, ventas por provincia,
--     ranking mensual por producto) usando las tablas del modelo estrella.
-- =====================================================================


-- Ejemplo: revisar la dimensión producto
SELECT product_key, name, category, family, list_price
FROM dim_product
ORDER BY product_key;


-- TU TURNO: agregá acá tus consultas.

-- Verifica que las cargas conservaron la cantidad de filas
SELECT
    'Pedidos' AS tabla,
    (SELECT COUNT(*) FROM raw.sales_order) AS filas_raw,
    (SELECT COUNT(*) FROM fact_order) AS filas_dw
UNION ALL

SELECT
    'Items',
    (SELECT COUNT(*) FROM raw.sales_order_item),
    (SELECT COUNT(*) FROM fact_order_item)
UNION ALL

SELECT
    'Pagos',
    (SELECT COUNT(*) FROM raw.payment),
    (SELECT COUNT(*) FROM fact_payment)
UNION ALL

SELECT
    'Envios',
    (SELECT COUNT(*) FROM raw.shipment),
    (SELECT COUNT(*) FROM fact_shipment)
UNION ALL

SELECT
    'Sesiones',
    (SELECT COUNT(*) FROM raw.web_session),
    (SELECT COUNT(*) FROM fact_web_session)
UNION ALL

SELECT
    'NPS',
    (SELECT COUNT(*) FROM raw.nps_response),
    (SELECT COUNT(*) FROM fact_nps_response);



-- Revisa pedidos sin provincia, separados por canal.
SELECT
    ch.code AS canal,
    COUNT(*) AS total_pedidos,
    COUNT(*) FILTER (
        WHERE o.province_key IS NULL
    ) AS pedidos_sin_provincia
FROM fact_order AS o
JOIN dim_channel AS ch ON o.channel_key = ch.channel_key
GROUP BY ch.code
ORDER BY ch.code;


-- Comparar los importes de origen y destino.
SELECT
    'Pedidos' AS tabla,
    (SELECT SUM(total_amount) FROM raw.sales_order) AS importe_raw,
    (SELECT SUM(total_amount) FROM fact_order) AS importe_dw
UNION ALL
SELECT
    'Items',
    (SELECT SUM(line_total) FROM raw.sales_order_item),
    (SELECT SUM(line_total) FROM fact_order_item)
UNION ALL
SELECT
    'Pagos',
    (SELECT SUM(amount) FROM raw.payment),
    (SELECT SUM(amount) FROM fact_payment);