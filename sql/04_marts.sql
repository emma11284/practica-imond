-- =====================================================================
-- 04_marts.sql — Tablas de resultados para el dashboard
-- =====================================================================
-- Los KPIs se calculan en SQL a partir del modelo estrella.
-- run_sql.py exporta automáticamente las tablas creadas a dw/.
-- =====================================================================


-- Ventas por día, canal y provincia.
-- Grano: una fila por combinación de esas tres claves.
CREATE TABLE mart_ventas_diarias AS
SELECT
    date_key,
    channel_key,
    province_key,
    COUNT(*) AS pedidos_vendidos,
    SUM(total_amount) AS ventas_con_iva_y_envio,
    SUM(total_amount - shipping_fee) AS ventas_con_iva_sin_envio,
    SUM(subtotal) AS ventas_sin_iva_ni_envio
FROM fact_order
WHERE status IN ('PAID', 'FULFILLED')
GROUP BY
    date_key,
    channel_key,
    province_key;


-- Ventas por día, producto, canal y provincia.
-- Grano: una fila por combinación de esas cuatro claves.
CREATE TABLE mart_ventas_producto_diarias AS
SELECT
    i.date_key,
    i.product_key,
    i.channel_key,
    o.province_key,
    SUM(i.quantity) AS unidades_vendidas,
    SUM(i.line_total) AS ventas_producto
FROM fact_order_item AS i
JOIN fact_order AS o
    ON i.order_id = o.order_id
WHERE o.status IN ('PAID', 'FULFILLED')
GROUP BY
    i.date_key,
    i.product_key,
    i.channel_key,
    o.province_key;


-- Ticket por período, canal y provincia.
-- Se calcula desde las ventas y pedidos del mart diario.
-- Incluye cada mes, todo el período y agrupaciones de canales/provincias.
CREATE TABLE mart_ticket_periodos AS
WITH ventas_diarias AS (
    SELECT
        strftime(d.fecha, '%Y-%m') AS mes,
        ch.name AS canal,
        p.name AS provincia,
        v.pedidos_vendidos,
        v.ventas_con_iva_y_envio
    FROM mart_ventas_diarias AS v
    JOIN dim_date AS d
        ON v.date_key = d.date_key
    JOIN dim_channel AS ch
        ON v.channel_key = ch.channel_key
    LEFT JOIN dim_province AS p
        ON v.province_key = p.province_key
)
SELECT
    CASE
        WHEN GROUPING(mes) = 1 THEN 'Todo el período'
        ELSE mes
    END AS periodo,

    CASE
        WHEN GROUPING(canal) = 1 THEN 'Todos los canales'
        ELSE canal
    END AS canal,

    CASE
        WHEN GROUPING(provincia) = 1 THEN 'Todas las provincias'
        ELSE provincia
    END AS provincia,

    SUM(pedidos_vendidos) AS pedidos_vendidos,
    SUM(ventas_con_iva_y_envio) AS ventas_totales,

    SUM(ventas_con_iva_y_envio)
        / NULLIF(SUM(pedidos_vendidos), 0) AS ticket_promedio

FROM ventas_diarias
GROUP BY CUBE(mes, canal, provincia);

-- Comprobar el ticket general.
SELECT *
FROM mart_ticket_periodos
WHERE periodo = 'Todo el período'
  AND canal = 'Todos los canales'
  AND provincia = 'Todas las provincias';


-- NPS por período y canal.
-- Incluye cada mes, todo el período y todos los canales.
CREATE TABLE mart_nps_periodos AS
WITH respuestas AS (
    SELECT
        CAST(DATE_TRUNC('month', d.fecha) AS DATE) AS mes,
        ch.name AS canal,
        n.score
    FROM fact_nps_response AS n
    JOIN dim_date AS d
        ON n.date_key = d.date_key
    JOIN dim_channel AS ch
        ON n.channel_key = ch.channel_key
),
resumen AS (
    SELECT
        mes,

        CASE
            WHEN GROUPING(canal) = 1 THEN 'Todos los canales'
            ELSE canal
        END AS canal,

        COUNT(*) AS total_respuestas,
        COUNT(*) FILTER (WHERE score >= 9) AS promotores,
        COUNT(*) FILTER (WHERE score BETWEEN 7 AND 8) AS pasivos,
        COUNT(*) FILTER (WHERE score <= 6) AS detractores,

        100.0 * COUNT(*) FILTER (WHERE score >= 9)
            / NULLIF(COUNT(*), 0) AS porcentaje_promotores,

        100.0 * COUNT(*) FILTER (WHERE score BETWEEN 7 AND 8)
            / NULLIF(COUNT(*), 0) AS porcentaje_pasivos,

        100.0 * COUNT(*) FILTER (WHERE score <= 6)
            / NULLIF(COUNT(*), 0) AS porcentaje_detractores,

        100.0 * (
            COUNT(*) FILTER (WHERE score >= 9)
            - COUNT(*) FILTER (WHERE score <= 6)
        ) / NULLIF(COUNT(*), 0) AS nps

    FROM respuestas
    GROUP BY CUBE(mes, canal)
)
SELECT
    COALESCE(
        strftime(mes, '%Y-%m'),
        'Todo el período'
    ) AS periodo,

    canal,
    YEAR(mes) AS anio,
    MONTH(mes) AS numero_mes,

    CASE MONTH(mes)
        WHEN 1 THEN 'enero'
        WHEN 2 THEN 'febrero'
        WHEN 3 THEN 'marzo'
        WHEN 4 THEN 'abril'
        WHEN 5 THEN 'mayo'
        WHEN 6 THEN 'junio'
        WHEN 7 THEN 'julio'
        WHEN 8 THEN 'agosto'
        WHEN 9 THEN 'septiembre'
        WHEN 10 THEN 'octubre'
        WHEN 11 THEN 'noviembre'
        WHEN 12 THEN 'diciembre'
    END AS nombre_mes,

    total_respuestas,
    promotores,
    pasivos,
    detractores,
    porcentaje_promotores,
    porcentaje_pasivos,
    porcentaje_detractores,
    nps
FROM resumen;

-- Comprobar el NPS general.
SELECT *
FROM mart_nps_periodos
WHERE periodo = 'Todo el período'
  AND canal = 'Todos los canales';


-- Actividad web por mes y para todo el período.
-- Indicador combinado: clientes identificados distintos más sesiones anónimas. No representa personas únicas.
CREATE TABLE mart_usuarios_periodos AS
WITH sesiones AS (
    SELECT
        CAST(DATE_TRUNC('month', d.fecha) AS DATE) AS mes,
        ws.customer_key
    FROM fact_web_session AS ws
    JOIN dim_date AS d
        ON ws.date_key = d.date_key
),
resumen AS (
    SELECT
        mes,

        COUNT(DISTINCT customer_key) AS clientes_identificados,

        COUNT(*) FILTER (
            WHERE customer_key IS NULL
        ) AS sesiones_anonimas,

        COUNT(DISTINCT customer_key)
            + COUNT(*) FILTER (
                WHERE customer_key IS NULL
            ) AS usuarios_activos

    FROM sesiones
    GROUP BY GROUPING SETS ((mes), ())
)
SELECT
    COALESCE(
        strftime(mes, '%Y-%m'),
        'Todo el período'
    ) AS periodo,

    YEAR(mes) AS anio,
    MONTH(mes) AS numero_mes,

    CASE MONTH(mes)
        WHEN 1 THEN 'enero'
        WHEN 2 THEN 'febrero'
        WHEN 3 THEN 'marzo'
        WHEN 4 THEN 'abril'
        WHEN 5 THEN 'mayo'
        WHEN 6 THEN 'junio'
        WHEN 7 THEN 'julio'
        WHEN 8 THEN 'agosto'
        WHEN 9 THEN 'septiembre'
        WHEN 10 THEN 'octubre'
        WHEN 11 THEN 'noviembre'
        WHEN 12 THEN 'diciembre'
    END AS nombre_mes,

    clientes_identificados,
    sesiones_anonimas,
    usuarios_activos
FROM resumen;

-- Comprobar el resultado general.
SELECT *
FROM mart_usuarios_periodos
WHERE periodo = 'Todo el período';


-- Sesiones web por día y fuente de tráfico.
-- Grano: una fila por fecha y fuente.
CREATE TABLE mart_sesiones_fuente_diarias AS
SELECT
    date_key,
    source AS fuente,
    COUNT(*) AS cantidad_sesiones
FROM fact_web_session
GROUP BY date_key, source;