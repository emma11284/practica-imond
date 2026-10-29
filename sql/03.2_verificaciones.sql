-- =====================================================================
-- VERIFICACIONES
-- =====================================================================

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


-- Control de correspondencia de registros entre RAW y DW.
-- Resultado esperado: 0 en ambas columnas para todas las tablas.
SELECT
    'Pedidos' AS tabla,
    (SELECT COUNT(*)
     FROM raw.sales_order AS r
     WHERE NOT EXISTS (
         SELECT 1 FROM fact_order AS f
         WHERE f.order_id = r.order_id
     )) AS registros_faltantes_en_dw,
    (SELECT COUNT(*)
     FROM fact_order AS f
     WHERE NOT EXISTS (
         SELECT 1 FROM raw.sales_order AS r
         WHERE r.order_id = f.order_id
     )) AS registros_sin_origen
UNION ALL
SELECT
    'Items',
    (SELECT COUNT(*)
     FROM raw.sales_order_item AS r
     WHERE NOT EXISTS (
         SELECT 1 FROM fact_order_item AS f
         WHERE f.order_item_id = r.order_item_id
     )),
    (SELECT COUNT(*)
     FROM fact_order_item AS f
     WHERE NOT EXISTS (
         SELECT 1 FROM raw.sales_order_item AS r
         WHERE r.order_item_id = f.order_item_id
     ))
UNION ALL
SELECT
    'Pagos',
    (SELECT COUNT(*)
     FROM raw.payment AS r
     WHERE NOT EXISTS (
         SELECT 1 FROM fact_payment AS f
         WHERE f.payment_id = r.payment_id
     )),
    (SELECT COUNT(*)
     FROM fact_payment AS f
     WHERE NOT EXISTS (
         SELECT 1 FROM raw.payment AS r
         WHERE r.payment_id = f.payment_id
     ))
UNION ALL
SELECT
    'Envios',
    (SELECT COUNT(*)
     FROM raw.shipment AS r
     WHERE NOT EXISTS (
         SELECT 1 FROM fact_shipment AS f
         WHERE f.shipment_id = r.shipment_id
     )),
    (SELECT COUNT(*)
     FROM fact_shipment AS f
     WHERE NOT EXISTS (
         SELECT 1 FROM raw.shipment AS r
         WHERE r.shipment_id = f.shipment_id
     ))
UNION ALL
SELECT
    'Sesiones',
    (SELECT COUNT(*)
     FROM raw.web_session AS r
     WHERE NOT EXISTS (
         SELECT 1 FROM fact_web_session AS f
         WHERE f.session_id = r.session_id
     )),
    (SELECT COUNT(*)
     FROM fact_web_session AS f
     WHERE NOT EXISTS (
         SELECT 1 FROM raw.web_session AS r
         WHERE r.session_id = f.session_id
     ))
UNION ALL
SELECT
    'NPS',
    (SELECT COUNT(*)
     FROM raw.nps_response AS r
     WHERE NOT EXISTS (
         SELECT 1 FROM fact_nps_response AS f
         WHERE f.nps_id = r.nps_id
     )),
    (SELECT COUNT(*)
     FROM fact_nps_response AS f
     WHERE NOT EXISTS (
         SELECT 1 FROM raw.nps_response AS r
         WHERE r.nps_id = f.nps_id
     ));


-- Control: importes de cada pedido y cálculo sin envío.
-- Resultado esperado: 0 en todas las columnas.
SELECT
    COUNT(*) FILTER (
        WHERE f.subtotal IS DISTINCT FROM r.subtotal
    ) AS diferencias_subtotal,

    COUNT(*) FILTER (
        WHERE f.tax_amount IS DISTINCT FROM r.tax_amount
    ) AS diferencias_impuestos,

    COUNT(*) FILTER (
        WHERE f.shipping_fee IS DISTINCT FROM r.shipping_fee
    ) AS diferencias_envio,

    COUNT(*) FILTER (
        WHERE f.total_amount IS DISTINCT FROM r.total_amount
    ) AS diferencias_total,

    COUNT(*) FILTER (
        WHERE f.amount_with_tax_without_shipping
            IS DISTINCT FROM (r.total_amount - r.shipping_fee)
    ) AS diferencias_monto_sin_envio

FROM fact_order AS f
JOIN raw.sales_order AS r
    ON f.order_id = r.order_id;

-- Une cada pedido con su original mediante order_id y cuenta cuántos tienen importes diferentes. También revisa la columna nueva.

-- Coherencia de importes.
-- Resultado esperado: 0 en ambas columnas.
SELECT
    (
        SELECT COUNT(*)
        FROM fact_order
        WHERE subtotal IS NULL
           OR tax_amount IS NULL
           OR shipping_fee IS NULL
           OR total_amount IS NULL
           OR total_amount <> subtotal + tax_amount + shipping_fee
    ) AS pedidos_con_importes_inconsistentes,

    (
        SELECT COUNT(*)
        FROM fact_order_item
        WHERE quantity IS NULL
           OR unit_price IS NULL
           OR discount_amount IS NULL
           OR line_total IS NULL
           OR line_total <> quantity * unit_price - discount_amount
    ) AS items_con_importes_inconsistentes;

-- Conciliación entre cabecera del pedido y sus ítems.
-- Resultado esperado: 0 en ambas columnas.
WITH detalle AS (
    SELECT
        order_id,
        COUNT(*) AS cantidad_items,
        SUM(line_total) AS total_items
    FROM fact_order_item
    GROUP BY order_id
)
SELECT
    COUNT(*) FILTER (
        WHERE d.order_id IS NULL
    ) AS pedidos_sin_items,

    COUNT(*) FILTER (
        WHERE d.order_id IS NOT NULL
          AND o.subtotal IS DISTINCT FROM d.total_items
    ) AS pedidos_con_diferencias
FROM fact_order AS o
LEFT JOIN detalle AS d
    ON o.order_id = d.order_id;

-- Relaciones de pedidos que se perdieron durante la carga.
-- Resultado esperado: 0 en todas las columnas.
SELECT
    COUNT(*) FILTER (
        WHERE r.customer_id IS NOT NULL
          AND f.customer_key IS NULL
    ) AS clientes_sin_asignar,

    COUNT(*) FILTER (
        WHERE r.channel_id IS NOT NULL
          AND f.channel_key IS NULL
    ) AS canales_sin_asignar,

    COUNT(*) FILTER (
        WHERE r.order_date IS NOT NULL
          AND f.date_key IS NULL
    ) AS fechas_sin_asignar,

    COUNT(*) FILTER (
        WHERE r.store_id IS NOT NULL
          AND f.store_key IS NULL
    ) AS tiendas_sin_asignar,

    COUNT(*) FILTER (
        WHERE a.province_id IS NOT NULL
          AND f.province_key IS NULL
    ) AS provincias_sin_asignar

FROM raw.sales_order AS r
JOIN fact_order AS f
    ON r.order_id = f.order_id
LEFT JOIN raw.address AS a
    ON r.shipping_address_id = a.address_id;

-- Cuenta únicamente cuando existe un dato de origen y falta su clave en el DW. 
-- Por ejemplo: que un pedido tenga cliente en RAW, pero haya quedado sin cliente en el DW.

-- Clientes identificados en RAW que quedaron sin asignar en DW.
-- Resultado esperado: 0 en ambas filas.
SELECT
    'Sesiones web' AS tabla,
    COUNT(*) AS clientes_sin_asignar
FROM raw.web_session AS r
JOIN fact_web_session AS f
    ON r.session_id = f.session_id
WHERE r.customer_id IS NOT NULL
  AND f.customer_key IS NULL

UNION ALL

SELECT
    'NPS',
    COUNT(*)
FROM raw.nps_response AS r
JOIN fact_nps_response AS f
    ON r.nps_id = f.nps_id
WHERE r.customer_id IS NOT NULL
  AND f.customer_key IS NULL;


-- Conservación de fechas y puntajes.
-- Resultado esperado: 0 en todos los controles.
SELECT
    'Fecha de pedido' AS control,
    COUNT(*) AS diferencias
FROM raw.sales_order AS r
JOIN fact_order AS f ON r.order_id = f.order_id
LEFT JOIN dim_date AS d ON f.date_key = d.date_key
WHERE d.fecha IS DISTINCT FROM CAST(r.order_date AS DATE)

UNION ALL

SELECT
    'Fecha de sesion',
    COUNT(*)
FROM raw.web_session AS r
JOIN fact_web_session AS f ON r.session_id = f.session_id
LEFT JOIN dim_date AS d ON f.date_key = d.date_key
WHERE d.fecha IS DISTINCT FROM CAST(r.started_at AS DATE)

UNION ALL

SELECT
    'Fecha de respuesta NPS',
    COUNT(*)
FROM raw.nps_response AS r
JOIN fact_nps_response AS f ON r.nps_id = f.nps_id
LEFT JOIN dim_date AS d ON f.date_key = d.date_key
WHERE d.fecha IS DISTINCT FROM CAST(r.responded_at AS DATE)

UNION ALL

SELECT
    'Puntaje NPS',
    COUNT(*)
FROM raw.nps_response AS r
JOIN fact_nps_response AS f ON r.nps_id = f.nps_id
WHERE f.score IS DISTINCT FROM r.score;



-- VERIFICACIONES KPIs
-- Comparación de Ventas y Ticket Promedio entre RAW y DW.
WITH origen AS (
    SELECT
        COUNT(*) AS pedidos,
        SUM(total_amount) AS ventas
    FROM raw.sales_order
    WHERE status IN ('PAID', 'FULFILLED')
),
destino AS (
    SELECT
        COUNT(*) AS pedidos,
        SUM(total_amount) AS ventas
    FROM fact_order
    WHERE status IN ('PAID', 'FULFILLED')
)
SELECT
    r.pedidos AS pedidos_raw,
    d.pedidos AS pedidos_dw,
    d.pedidos - r.pedidos AS diferencia_pedidos,

    r.ventas AS ventas_raw,
    d.ventas AS ventas_dw,
    d.ventas - r.ventas AS diferencia_ventas,

    ROUND(r.ventas / NULLIF(r.pedidos, 0), 2) AS ticket_raw,
    ROUND(d.ventas / NULLIF(d.pedidos, 0), 2) AS ticket_dw,

    ROUND(
        d.ventas / NULLIF(d.pedidos, 0)
        - r.ventas / NULLIF(r.pedidos, 0),
        2
    ) AS diferencia_ticket
FROM origen AS r
CROSS JOIN destino AS d;


-- Comparación de actividad web y NPS entre RAW y DW.
-- Resultado esperado: diferencia 0 en los tres indicadores.
WITH usuarios AS (
    SELECT
        'RAW' AS origen,
        COUNT(DISTINCT customer_id) AS clientes_identificados,
        COUNT(*) FILTER (
            WHERE customer_id IS NULL
        ) AS sesiones_anonimas
    FROM raw.web_session

    UNION ALL

    SELECT
        'DW',
        COUNT(DISTINCT customer_key),
        COUNT(*) FILTER (
            WHERE customer_key IS NULL
        )
    FROM fact_web_session
),
nps AS (
    SELECT
        'RAW' AS origen,
        100.0 * (
            COUNT(*) FILTER (WHERE score >= 9)
            - COUNT(*) FILTER (WHERE score <= 6)
        ) / NULLIF(COUNT(*), 0) AS valor
    FROM raw.nps_response

    UNION ALL

    SELECT
        'DW',
        100.0 * (
            COUNT(*) FILTER (WHERE score >= 9)
            - COUNT(*) FILTER (WHERE score <= 6)
        ) / NULLIF(COUNT(*), 0)
    FROM fact_nps_response
)
SELECT
    'Clientes identificados con sesión' AS indicador,
    CAST(r.clientes_identificados AS DOUBLE) AS valor_raw,
    CAST(d.clientes_identificados AS DOUBLE) AS valor_dw,
    CAST(
        d.clientes_identificados - r.clientes_identificados
        AS DOUBLE
    ) AS diferencia
FROM usuarios AS r
CROSS JOIN usuarios AS d
WHERE r.origen = 'RAW' AND d.origen = 'DW'

UNION ALL

SELECT
    'Sesiones anónimas',
    CAST(r.sesiones_anonimas AS DOUBLE),
    CAST(d.sesiones_anonimas AS DOUBLE),
    CAST(d.sesiones_anonimas - r.sesiones_anonimas AS DOUBLE)
FROM usuarios AS r
CROSS JOIN usuarios AS d
WHERE r.origen = 'RAW' AND d.origen = 'DW'

UNION ALL

SELECT
    'NPS',
    r.valor,
    d.valor,
    d.valor - r.valor
FROM nps AS r
CROSS JOIN nps AS d
WHERE r.origen = 'RAW' AND d.origen = 'DW';


-- Compara ventas por provincia entre RAW y DW.
-- Incluye los pedidos sin provincia como un grupo.
WITH origen AS (
    SELECT
        a.province_id,
        SUM(o.total_amount) AS ventas
    FROM raw.sales_order AS o
    LEFT JOIN raw.address AS a
        ON o.shipping_address_id = a.address_id
    WHERE o.status IN ('PAID', 'FULFILLED')
    GROUP BY a.province_id
),
destino AS (
    SELECT
        p.province_id,
        SUM(o.total_amount) AS ventas
    FROM fact_order AS o
    LEFT JOIN dim_province AS p
        ON o.province_key = p.province_key
    WHERE o.status IN ('PAID', 'FULFILLED')
    GROUP BY p.province_id
)
SELECT
    COALESCE(r.province_id, d.province_id) AS province_id,
    r.ventas AS ventas_raw,
    d.ventas AS ventas_dw,
    d.ventas - r.ventas AS diferencia,
    CASE
        WHEN r.ventas IS NOT DISTINCT FROM d.ventas
            THEN 'OK'
        ELSE 'REVISAR'
    END AS resultado
FROM origen AS r
FULL OUTER JOIN destino AS d
    ON r.province_id IS NOT DISTINCT FROM d.province_id
ORDER BY province_id;


-- Comparación del ranking mensual por producto entre RAW y DW.
WITH origen AS (
    SELECT
        CAST(DATE_TRUNC('month', o.order_date) AS DATE) AS mes,
        i.product_id,
        SUM(i.line_total) AS ventas
    FROM raw.sales_order_item AS i
    JOIN raw.sales_order AS o
        ON i.order_id = o.order_id
    WHERE o.status IN ('PAID', 'FULFILLED')
    GROUP BY
        CAST(DATE_TRUNC('month', o.order_date) AS DATE),
        i.product_id
),
destino AS (
    SELECT
        CAST(DATE_TRUNC('month', d.fecha) AS DATE) AS mes,
        p.product_id,
        SUM(i.line_total) AS ventas
    FROM fact_order_item AS i
    JOIN dim_date AS d
        ON i.date_key = d.date_key
    JOIN dim_product AS p
        ON i.product_key = p.product_key
    WHERE i.order_status IN ('PAID', 'FULFILLED')
    GROUP BY
        CAST(DATE_TRUNC('month', d.fecha) AS DATE),
        p.product_id
),
ranking_raw AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY mes ORDER BY ventas DESC
        ) AS puesto
    FROM origen
),
ranking_dw AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY mes ORDER BY ventas DESC
        ) AS puesto
    FROM destino
)
SELECT
    COALESCE(r.mes, d.mes) AS mes,
    COALESCE(r.product_id, d.product_id) AS product_id,
    r.ventas AS ventas_raw,
    d.ventas AS ventas_dw,
    d.ventas - r.ventas AS diferencia,
    r.puesto AS puesto_raw,
    d.puesto AS puesto_dw,
    CASE
        WHEN r.ventas IS NOT DISTINCT FROM d.ventas
         AND r.puesto IS NOT DISTINCT FROM d.puesto
            THEN 'OK'
        ELSE 'REVISAR'
    END AS resultado
FROM ranking_raw AS r
FULL OUTER JOIN ranking_dw AS d
    ON r.mes = d.mes
   AND r.product_id = d.product_id
WHERE r.ventas IS DISTINCT FROM d.ventas
OR r.puesto IS DISTINCT FROM d.puesto
ORDER BY mes, puesto_raw, product_id;