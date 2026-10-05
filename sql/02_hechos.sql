-- =====================================================================
-- 02_hechos.sql — Tablas de HECHOS del modelo estrella
-- =====================================================================
-- Este archivo se ejecuta después de 01_dimensiones.sql porque los hechos
-- apuntan a las dimensiones con FOREIGN KEY (REFERENCES).
--
-- Para cada tabla de hechos:
--   1. Definí el GRANO: ¿qué representa UNA fila?
--      (ej.: un producto dentro de un pedido, una sesión web, una respuesta NPS)
--   2. CREATE TABLE con:
--        - PRIMARY KEY
--        - una FOREIGN KEY por cada dimensión:  product_key INTEGER REFERENCES dim_product (product_key)
--        - las métricas (cantidades, importes, puntajes...)
--   3. INSERT INTO ... SELECT uniendo las tablas de origen (raw.) con las dimensiones
--      para obtener las claves.
--
-- Patrón para obtener la clave de una dimensión:
--
--   SELECT i.order_item_id, p.product_key, i.quantity, i.line_total
--   FROM raw.sales_order_item AS i
--   JOIN dim_product AS p ON p.product_id = i.product_id
--
-- Si una FOREIGN KEY apunta a una clave que no existe en la dimensión,
-- DuckDB rechaza la carga y run_sql.py te muestra el error.
-- =====================================================================


-- TU TURNO: creá acá las tablas de hechos.

-- Hecho Pedido
CREATE TABLE fact_order (
    order_id     BIGINT PRIMARY KEY,
    customer_key INTEGER,
    channel_key  INTEGER NOT NULL,
    date_key     INTEGER NOT NULL,
    store_key    INTEGER,
    province_key INTEGER 
        REFERENCES dim_province(province_key),
    status       VARCHAR,
    currency_code VARCHAR,
    subtotal     DECIMAL(12,2),
    tax_amount   DECIMAL(12,2),
    shipping_fee DECIMAL(12,2),
    total_amount DECIMAL(12,2),

    FOREIGN KEY (customer_key)
        REFERENCES dim_customer(customer_key),
    FOREIGN KEY (channel_key)
        REFERENCES dim_channel(channel_key),
    FOREIGN KEY (date_key)
        REFERENCES dim_date(date_key),
    FOREIGN KEY (store_key)
        REFERENCES dim_store(store_key)
);

INSERT INTO fact_order
SELECT
    o.order_id,
    c.customer_key,
    ch.channel_key,
    d.date_key,
    s.store_key,
    pr.province_key,
    o.status,
    o.currency_code,
    o.subtotal,
    o.tax_amount,
    o.shipping_fee,
    o.total_amount
FROM raw.sales_order AS o
LEFT JOIN dim_customer AS c
    ON o.customer_id = c.customer_id
LEFT JOIN dim_channel AS ch
    ON o.channel_id = ch.channel_id
LEFT JOIN dim_date AS d
    ON CAST(o.order_date AS DATE) = d.fecha
LEFT JOIN dim_store s 
    ON o.store_id = s.store_id
LEFT JOIN raw.address AS a 
    ON o.shipping_address_id = a.address_id
LEFT JOIN dim_province AS pr 
    ON a.province_id = pr.province_id;


-- Hecho Order Item
CREATE TABLE fact_order_item (
    order_item_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_key INTEGER NOT NULL REFERENCES dim_product(product_key),
    customer_key INTEGER REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL REFERENCES dim_channel(channel_key),
    date_key INTEGER NOT NULL REFERENCES dim_date(date_key),
    store_key INTEGER REFERENCES dim_store(store_key),
    order_status VARCHAR,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(12, 2) NOT NULL,
    discount_amount DECIMAL(12, 2) NOT NULL,
    line_total DECIMAL(12, 2) NOT NULL
);

INSERT INTO fact_order_item (
    order_item_id, order_id, product_key, customer_key,
    channel_key, date_key, store_key, order_status,
    quantity, unit_price, discount_amount, line_total
)
SELECT
    i.order_item_id,
    i.order_id,
    p.product_key,
    c.customer_key,
    ch.channel_key,
    d.date_key,
    s.store_key,
    o.status,
    i.quantity,
    i.unit_price,
    i.discount_amount,
    i.line_total
FROM raw.sales_order_item AS i
JOIN raw.sales_order AS o ON i.order_id = o.order_id
LEFT JOIN dim_product AS p ON i.product_id = p.product_id
LEFT JOIN dim_customer AS c ON o.customer_id = c.customer_id
LEFT JOIN dim_channel AS ch ON o.channel_id = ch.channel_id
LEFT JOIN dim_date AS d ON CAST(o.order_date AS DATE) = d.fecha
LEFT JOIN dim_store AS s ON o.store_id = s.store_id;


-- Hecho Pagos
CREATE TABLE fact_payment (
    payment_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    customer_key INTEGER 
        REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL 
        REFERENCES dim_channel(channel_key),
    store_key INTEGER 
        REFERENCES dim_store(store_key),
    payment_date_key INTEGER 
        REFERENCES dim_date(date_key),

    method VARCHAR NOT NULL
        CHECK (method IN ('CASH', 'CARD', 'TRANSFER', 'GATEWAY')),
    status VARCHAR NOT NULL
        CHECK (status IN ('PENDING', 'PAID', 'FAILED', 'REFUNDED')),
    amount DECIMAL(12, 2) NOT NULL,
    paid_at TIMESTAMP,
    transaction_ref VARCHAR
);

INSERT INTO fact_payment (
    payment_id, order_id, customer_key, channel_key,
    store_key, payment_date_key, method, status,
    amount, paid_at, transaction_ref
)
SELECT
    pay.payment_id,
    pay.order_id,
    c.customer_key,
    ch.channel_key,
    s.store_key,
    d.date_key,
    pay.method,
    pay.status,
    pay.amount,
    pay.paid_at,
    pay.transaction_ref
FROM raw.payment AS pay
JOIN raw.sales_order AS o 
    ON pay.order_id = o.order_id
LEFT JOIN dim_customer AS c 
    ON o.customer_id = c.customer_id
LEFT JOIN dim_channel AS ch 
    ON o.channel_id = ch.channel_id
LEFT JOIN dim_store AS s 
    ON o.store_id = s.store_id
LEFT JOIN dim_date AS d 
    ON CAST(pay.paid_at AS DATE) = d.fecha;


-- Hecho: Envíos
CREATE TABLE fact_shipment (
    shipment_id BIGINT PRIMARY KEY,
    order_id BIGINT NOT NULL,
    customer_key INTEGER 
        REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL 
        REFERENCES dim_channel(channel_key),
    store_key INTEGER 
        REFERENCES dim_store(store_key),
    shipped_date_key INTEGER 
        REFERENCES dim_date(date_key),
    delivered_date_key INTEGER 
        REFERENCES dim_date(date_key),
    carrier VARCHAR,
    tracking_number VARCHAR,
    status VARCHAR NOT NULL
        CHECK (status IN ('READY', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
    shipped_at TIMESTAMP,
    delivered_at TIMESTAMP
);

INSERT INTO fact_shipment (
    shipment_id, order_id, customer_key, channel_key,
    store_key, shipped_date_key, delivered_date_key,
    carrier, tracking_number, status, shipped_at, delivered_at
)
SELECT
    sh.shipment_id,
    sh.order_id,
    c.customer_key,
    ch.channel_key,
    s.store_key,
    ds.date_key,
    dd.date_key,
    sh.carrier,
    sh.tracking_number,
    sh.status,
    sh.shipped_at,
    sh.delivered_at
FROM raw.shipment AS sh
JOIN raw.sales_order AS o  
    ON sh.order_id = o.order_id
LEFT JOIN dim_customer AS c 
    ON o.customer_id = c.customer_id
LEFT JOIN dim_channel AS ch 
    ON o.channel_id = ch.channel_id
LEFT JOIN dim_store AS s 
    ON o.store_id = s.store_id
LEFT JOIN dim_date AS ds 
    ON CAST(sh.shipped_at AS DATE) = ds.fecha
LEFT JOIN dim_date AS dd 
    ON CAST(sh.delivered_at AS DATE) = dd.fecha;


-- Hecho Sesiones Web
CREATE TABLE fact_web_session (
    session_id BIGINT PRIMARY KEY,
    customer_key INTEGER 
        REFERENCES dim_customer(customer_key),
    date_key INTEGER NOT NULL 
        REFERENCES dim_date(date_key),
    started_at TIMESTAMP NOT NULL,
    ended_at TIMESTAMP,
    source VARCHAR,
    device VARCHAR
);

INSERT INTO fact_web_session (
    session_id, customer_key, date_key,
    started_at, ended_at, source, device
)
SELECT
    ws.session_id,
    c.customer_key,
    d.date_key,
    ws.started_at,
    ws.ended_at,
    ws.source,
    ws.device
FROM raw.web_session AS ws
LEFT JOIN dim_customer AS c 
    ON ws.customer_id = c.customer_id
LEFT JOIN dim_date AS d 
    ON CAST(ws.started_at AS DATE) = d.fecha;


-- Grano: una respuesta a la encuesta NPS.
CREATE TABLE fact_nps_response (
    nps_id BIGINT PRIMARY KEY,
    customer_key INTEGER 
        REFERENCES dim_customer(customer_key),
    channel_key INTEGER NOT NULL 
        REFERENCES dim_channel(channel_key),
    date_key INTEGER NOT NULL 
        REFERENCES dim_date(date_key),
    score SMALLINT NOT NULL CHECK (score BETWEEN 0 AND 10),
    comment TEXT,
    responded_at TIMESTAMP NOT NULL
);

INSERT INTO fact_nps_response (
    nps_id, customer_key, channel_key, date_key,
    score, comment, responded_at
)
SELECT
    n.nps_id,
    c.customer_key,
    ch.channel_key,
    d.date_key,
    n.score,
    n.comment,
    n.responded_at
FROM raw.nps_response AS n
LEFT JOIN dim_customer AS c 
    ON n.customer_id = c.customer_id
LEFT JOIN dim_channel AS ch 
    ON n.channel_id = ch.channel_id
LEFT JOIN dim_date AS d 
    ON CAST(n.responded_at AS DATE) = d.fecha;