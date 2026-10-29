# Modelo estrella

Generado por `run_sql.py` a partir de las tablas de `warehouse.duckdb`.

```mermaid
erDiagram
    dim_channel ||--o{ fact_nps_response : "channel_key"
    dim_channel ||--o{ fact_order : "channel_key"
    dim_channel ||--o{ fact_order_item : "channel_key"
    dim_channel ||--o{ fact_payment : "channel_key"
    dim_channel ||--o{ fact_shipment : "channel_key"
    dim_customer ||--o{ fact_nps_response : "customer_key"
    dim_customer ||--o{ fact_order : "customer_key"
    dim_customer ||--o{ fact_order_item : "customer_key"
    dim_customer ||--o{ fact_payment : "customer_key"
    dim_customer ||--o{ fact_shipment : "customer_key"
    dim_customer ||--o{ fact_web_session : "customer_key"
    dim_date ||--o{ fact_nps_response : "date_key"
    dim_date ||--o{ fact_order : "date_key"
    dim_date ||--o{ fact_order_item : "date_key"
    dim_date ||--o{ fact_payment : "payment_date_key"
    dim_date ||--o{ fact_shipment : "delivered_date_key"
    dim_date ||--o{ fact_shipment : "shipped_date_key"
    dim_date ||--o{ fact_web_session : "date_key"
    dim_product ||--o{ fact_order_item : "product_key"
    dim_province ||--o{ fact_order : "province_key"
    dim_store ||--o{ fact_order : "store_key"
    dim_store ||--o{ fact_order_item : "store_key"
    dim_store ||--o{ fact_payment : "store_key"
    dim_store ||--o{ fact_shipment : "store_key"
    dim_channel {
        INTEGER channel_key PK
        INTEGER channel_id
        VARCHAR code
        VARCHAR name
    }
    dim_customer {
        INTEGER customer_key PK
        INTEGER customer_id
        VARCHAR email
        VARCHAR first_name
        VARCHAR last_name
        VARCHAR phone
        VARCHAR status
        TIMESTAMP created_at
    }
    dim_date {
        INTEGER date_key PK
        DATE fecha
        INTEGER anio
        INTEGER mes
        INTEGER dia
        INTEGER trimestre
    }
    dim_product {
        INTEGER product_key PK
        INTEGER product_id
        VARCHAR sku
        VARCHAR name
        VARCHAR category
        VARCHAR family
        DECIMAL list_price
    }
    dim_province {
        INTEGER province_key PK
        INTEGER province_id
        VARCHAR name
        VARCHAR code
    }
    dim_store {
        INTEGER store_key PK
        INTEGER store_id
        VARCHAR name
        VARCHAR city
        VARCHAR province
        VARCHAR postal_code
    }
    fact_nps_response {
        BIGINT nps_id PK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER date_key FK
        SMALLINT score
        VARCHAR comment
        TIMESTAMP responded_at
    }
    fact_order {
        BIGINT order_id PK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER date_key FK
        INTEGER store_key FK
        INTEGER province_key FK
        VARCHAR status
        VARCHAR currency_code
        DECIMAL subtotal
        DECIMAL tax_amount
        DECIMAL shipping_fee
        DECIMAL total_amount
        DECIMAL amount_with_tax_without_shipping
    }
    fact_order_item {
        BIGINT order_item_id PK
        BIGINT order_id
        INTEGER product_key FK
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER date_key FK
        INTEGER store_key FK
        VARCHAR order_status
        INTEGER quantity
        DECIMAL unit_price
        DECIMAL discount_amount
        DECIMAL line_total
    }
    fact_payment {
        BIGINT payment_id PK
        BIGINT order_id
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER store_key FK
        INTEGER payment_date_key FK
        VARCHAR method
        VARCHAR status
        DECIMAL amount
        TIMESTAMP paid_at
        VARCHAR transaction_ref
    }
    fact_shipment {
        BIGINT shipment_id PK
        BIGINT order_id
        INTEGER customer_key FK
        INTEGER channel_key FK
        INTEGER store_key FK
        INTEGER shipped_date_key FK
        INTEGER delivered_date_key FK
        VARCHAR carrier
        VARCHAR tracking_number
        VARCHAR status
        TIMESTAMP shipped_at
        TIMESTAMP delivered_at
    }
    fact_web_session {
        BIGINT session_id PK
        INTEGER customer_key FK
        INTEGER date_key FK
        TIMESTAMP started_at
        TIMESTAMP ended_at
        VARCHAR source
        VARCHAR device
    }
    mart_nps_periodos {
        VARCHAR periodo
        VARCHAR canal
        BIGINT anio
        BIGINT numero_mes
        VARCHAR nombre_mes
        BIGINT total_respuestas
        BIGINT promotores
        BIGINT pasivos
        BIGINT detractores
        DOUBLE porcentaje_promotores
        DOUBLE porcentaje_pasivos
        DOUBLE porcentaje_detractores
        DOUBLE nps
    }
    mart_sesiones_fuente_diarias {
        INTEGER date_key
        VARCHAR fuente
        BIGINT cantidad_sesiones
    }
    mart_ticket_periodos {
        VARCHAR periodo
        VARCHAR canal
        VARCHAR provincia
        HUGEINT pedidos_vendidos
        DECIMAL ventas_totales
        DOUBLE ticket_promedio
    }
    mart_usuarios_periodos {
        VARCHAR periodo
        BIGINT anio
        BIGINT numero_mes
        VARCHAR nombre_mes
        BIGINT clientes_identificados
        BIGINT sesiones_anonimas
        BIGINT usuarios_activos
    }
    mart_ventas_diarias {
        INTEGER date_key
        INTEGER channel_key
        INTEGER province_key
        BIGINT pedidos_vendidos
        DECIMAL ventas_con_iva_y_envio
        DECIMAL ventas_con_iva_sin_envio
        DECIMAL ventas_sin_iva_ni_envio
    }
    mart_ventas_producto_diarias {
        INTEGER date_key
        INTEGER product_key
        INTEGER channel_key
        INTEGER province_key
        HUGEINT unidades_vendidas
        DECIMAL ventas_producto
    }
```
