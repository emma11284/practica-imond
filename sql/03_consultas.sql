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


-- KPI: ventas totales de pedidos pagados o completados.
SELECT
    SUM(total_amount) AS ventas_totales
FROM fact_order
WHERE status IN ('PAID', 'FULFILLED');


-- KPI: importe promedio por pedido pagado o completado.
SELECT
    COUNT(*) AS cantidad_pedidos,
    SUM(total_amount) AS ventas_totales,
    ROUND(
        SUM(total_amount) / NULLIF(COUNT(*), 0),
        2
    ) AS ticket_promedio
FROM fact_order
WHERE status IN ('PAID', 'FULFILLED');


-- KPI: usuarios activos en todo el período disponible.
SELECT
    COUNT(DISTINCT customer_key) AS clientes_identificados,
    COUNT(*) FILTER (
        WHERE customer_key IS NULL
    ) AS sesiones_anonimas,
    COUNT(DISTINCT customer_key)
        + COUNT(*) FILTER (
            WHERE customer_key IS NULL
        ) AS usuarios_activos
FROM fact_web_session;


-- KPI: NPS de todo el período disponible.
SELECT
    COUNT(*) AS total_respuestas,
    COUNT(*) FILTER (WHERE score >= 9) AS promotores,
    COUNT(*) FILTER (WHERE score <= 6) AS detractores,
    ROUND(
        100.0 * (
            COUNT(*) FILTER (WHERE score >= 9)
            - COUNT(*) FILTER (WHERE score <= 6)
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS nps
FROM fact_nps_response;


-- KPI: ventas por provincia.
SELECT
    p.name AS provincia,
    SUM(o.total_amount) AS ventas_totales
FROM fact_order AS o
JOIN dim_province AS p ON o.province_key = p.province_key
WHERE o.status IN ('PAID', 'FULFILLED')
GROUP BY p.name
ORDER BY ventas_totales DESC;


-- KPI: ranking mensual de productos por importe vendido.
WITH ventas_mensuales AS (
    SELECT
        CAST(DATE_TRUNC('month', d.fecha) AS DATE) AS mes,
        p.product_key,
        p.name AS producto,
        SUM(i.line_total) AS ventas_producto
    FROM fact_order_item AS i
    JOIN dim_product AS p 
        ON i.product_key = p.product_key
    JOIN dim_date AS d 
        ON i.date_key = d.date_key
    WHERE i.order_status IN ('PAID', 'FULFILLED')
    GROUP BY
        CAST(DATE_TRUNC('month', d.fecha) AS DATE),
        p.product_key,
        p.name
)
SELECT
    mes,
    producto,
    ventas_producto,
    DENSE_RANK() OVER (
        PARTITION BY mes
        ORDER BY ventas_producto DESC
    ) AS puesto
FROM ventas_mensuales
ORDER BY mes, puesto, producto;


-- KPI: ventas por día.
SELECT
    d.fecha,
    SUM(o.total_amount) AS ventas_totales
FROM fact_order AS o
JOIN dim_date AS d ON o.date_key = d.date_key
WHERE o.status IN ('PAID', 'FULFILLED')
GROUP BY d.fecha
ORDER BY d.fecha;


-- KPI: usuarios activos por día.
SELECT
    d.fecha,
    COUNT(DISTINCT ws.customer_key)
        + COUNT(*) FILTER (
            WHERE ws.customer_key IS NULL
        ) AS usuarios_activos
FROM fact_web_session AS ws
JOIN dim_date AS d ON ws.date_key = d.date_key
GROUP BY d.fecha
ORDER BY d.fecha;


-- KPI: tendencia diaria del NPS por canal.
SELECT
    d.fecha,
    ch.code AS canal,
    COUNT(*) AS total_respuestas,
    COUNT(*) FILTER (WHERE n.score >= 9) AS promotores,
    COUNT(*) FILTER (WHERE n.score <= 6) AS detractores,
    ROUND(
        100.0 * (
            COUNT(*) FILTER (WHERE n.score >= 9)
            - COUNT(*) FILTER (WHERE n.score <= 6)
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS nps
FROM fact_nps_response AS n
JOIN dim_date AS d ON n.date_key = d.date_key
JOIN dim_channel AS ch ON n.channel_key = ch.channel_key
GROUP BY d.fecha, ch.code
ORDER BY d.fecha, ch.code;


