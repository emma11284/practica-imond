# EcoBottle AR — Data warehouse y análisis comercial

Proyecto académico de Introducción al Marketing Online y los
Negocios Digitales.

El objetivo es construir un modelo estrella para analizar ventas
online y en tiendas físicas, usuarios activos, ticket promedio,
NPS, ventas por provincia y ranking mensual por producto.


## Origen de los datos

Los datos de muestra y el script de ejecución provienen del
[repositorio de la cátedra](https://github.com/AugustoCarmona/practica-imond).

Los CSV de `raw/` representan el sistema comercial de EcoBottle AR.
Contienen pedidos desde el 01/01/2024 hasta el 30/09/2025.
Los datos de origen se conservan sin modificaciones.

El desarrollo de este fork incluye las transformaciones SQL,
las dimensiones y hechos, las consultas de KPIs y su documentación.


## Estructura del proyecto

| Ruta | Contenido |
|---|---|
| `raw/` | CSV de origen |
| `sql/01_dimensiones.sql` | Creación y carga de dimensiones |
| `sql/02_hechos.sql` | Creación y carga de hechos |
| `sql/03_consultas.sql` | Validaciones y consultas de KPIs |
| `run_sql.py` | Script de ejecución y exportación provisto por la cátedra |
| `requirements.txt` | Dependencias de Python |
| `dw/` | CSV del data warehouse y diagrama generado |
| `assets/` | Diagrama de las tablas de origen |
| `generator/` | Generador de datos de muestra; no se necesita para ejecutar el proyecto |


## Instrucciones de ejecución

Requisitos: Git y Python 3.9 o superior.


### Instalación local en Windows (CMD)

```bat
git clone https://github.com/emma11284/practica-imond.git
cd practica-imond
python -m venv .venv
.venv\Scripts\activate.bat
python -m pip install -r requirements.txt
```

Cada vez que se abre una terminal nueva, se debe ingresar
a la carpeta del proyecto y activar nuevamente `.venv`.


### Construcción del data warehouse

```bat
python run_sql.py
```

El script reconstruye `warehouse.duckdb`, carga los CSV de origen,
ejecuta los archivos SQL en orden alfabético, muestra los resultados
de las consultas y exporta las tablas a `dw/`.

También genera `dw/modelo_estrella.md`.
La base `warehouse.duckdb` está excluida de Git mediante `.gitignore`.


### Exploración opcional

```bat
python run_sql.py --explorar
```

Abre las tablas de origen sin ejecutar las transformaciones SQL.

```bat
python run_sql.py --ui
```

Construye el DW y abre la interfaz para explorar el modelo.
Para cerrar la interfaz, se vuelve a la terminal y se presiona Enter.

El diagrama puede visualizarse en GitHub o en VS Code mediante
la extensión Markdown Preview Mermaid Support y Ctrl + Shift + V.


## Gestión del repositorio

La gestión de Git se realiza desde la consola.
Los commits siguen el formato Conventional Commits, utilizando
prefijos como `feat:`, `test:` y `docs:`.


## Dashboard

Pendiente de desarrollo. Se incorporarán el enlace y las capturas
del tablero terminado.


## Implementación del modelo estrella

El proyecto transforma los CSV de `raw/` en un data warehouse
para analizar la actividad comercial de EcoBottle AR.

Las transformaciones están escritas en SQL y se ejecutan mediante
`run_sql.py`. Las tablas resultantes se exportan como CSV a `dw/`.


### Dimensiones

Las dimensiones describen los datos que usamos para analizar
los hechos comerciales.

| Tabla | Qué describe | Clave primaria |
|---|---|---|
| dim_product | Productos, categorías y familias | product_key |
| dim_customer | Clientes | customer_key |
| dim_channel | Canales ONLINE y OFFLINE | channel_key |
| dim_province | Provincias | province_key |
| dim_store | Tiendas y su ubicación | store_key |
| dim_date | Calendario: fecha, año, mes, día y trimestre | date_key |


### Tablas de hechos y grano

El grano indica qué representa una fila de cada tabla.

| Tabla | Qué representa una fila | Clave primaria |
|---|---|---|
| fact_order | Un pedido | order_id |
| fact_order_item | Una línea de producto de un pedido | order_item_id |
| fact_payment | Un registro de pago | payment_id |
| fact_shipment | Un envío | shipment_id |
| fact_web_session | Una sesión de navegación web | session_id |
| fact_nps_response | Una respuesta a la encuesta NPS | nps_id |

Las tablas de hechos se relacionan con las dimensiones mediante
claves foráneas. Por ejemplo, `fact_order_item.product_key`
referencia a `dim_product.product_key`.


### Supuestos y reglas de cálculo

- Los importes están expresados en pesos argentinos (ARS).
- Las fechas y horas de origen corresponden a la hora de Argentina.
- Ventas y ticket promedio incluyen únicamente pedidos con estado
  `PAID` o `FULFILLED`. Los demás estados se conservan en las tablas
  de hechos, pero se excluyen de estos KPIs.
- Ventas se calcula sumando `fact_order.total_amount`, que incluye
  impuestos y costo de envío.
- Ticket promedio se calcula dividiendo las ventas por la cantidad
  de pedidos incluidos, no por la cantidad de productos.
- La provincia de venta se obtiene de la dirección de envío.
  En las compras en tienda, el conjunto de datos utiliza la dirección
  de la tienda como dirección de envío.
- El ranking mensual por producto utiliza `line_total`, después del
  descuento y sin agregar impuestos ni envío. Incluye pedidos con
  estado `PAID` o `FULFILLED`.
- Usuarios activos cuenta cada cliente identificado una sola vez
  dentro del período consultado. Cada sesión anónima se cuenta como
  una unidad adicional, porque no se puede identificar a la persona.
- Los usuarios activos de un mes se calculan sobre todo el mes:
  no se obtienen sumando los conteos diarios.
- NPS se calcula como:
  `100 × (promotores - detractores) / total de respuestas`.
  Promotores: puntajes 9–10; detractores: 0–6; pasivos: 7–8.
  Los pasivos se incluyen en el total de respuestas.
- El NPS de un período se calcula con sus respuestas:
  no se obtiene promediando los NPS diarios.
- Las respuestas NPS no se vinculan con un pedido específico,
  porque el origen no contiene `order_id`.
- Se conservan los valores `NULL` para datos opcionales, como
  clientes anónimos, tiendas en pedidos online y fechas de eventos
  que todavía no ocurrieron.
- La dimensión de fechas abarca desde el 02/03/2023 hasta el
  30/09/2025. Si se incorporan datos fuera de ese intervalo,
  debe ampliarse el calendario.
- El modelo conserva los atributos disponibles de los maestros,
  sin implementar un historial de cambios de las dimensiones.


### Diccionario de datos: dimensiones

PK significa clave primaria: identifica una fila y no admite
duplicados ni valores NULL.

NOT NULL indica que el dato es obligatorio.
UNIQUE indica que no puede repetirse.
Las columnas sin NOT NULL ni PK permiten NULL.

Las claves subrogadas se generan con ROW_NUMBER(), ordenando
por el ID de origen. Se recalculan en cada reconstrucción del DW;
no se garantiza que permanezcan iguales si cambia el conjunto
de IDs de origen.

#### dim_product

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| product_key | INTEGER | PK | Clave subrogada del producto |
| product_id | INTEGER | NOT NULL | ID del producto en el origen |
| sku | VARCHAR | NOT NULL | Código comercial del producto |
| name | VARCHAR | NOT NULL | Nombre del producto |
| category | VARCHAR | Permite NULL | Categoría; en estos datos, Classic o Sport |
| family | VARCHAR | Permite NULL | Categoría padre; en estos datos, Bottles |
| list_price | DECIMAL(12,2) | Permite NULL | Precio de lista en ARS, sin IVA |

La categoría y su familia se incorporan a la misma fila del
producto mediante uniones con raw.product_category.

#### dim_customer

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| customer_key | INTEGER | PK | Clave subrogada del cliente |
| customer_id | INTEGER | NOT NULL, UNIQUE | ID del cliente en el origen |
| email | VARCHAR | Permite NULL | Correo electrónico |
| first_name | VARCHAR | Permite NULL | Nombre |
| last_name | VARCHAR | Permite NULL | Apellido |
| phone | VARCHAR | Permite NULL | Teléfono |
| status | VARCHAR | Permite NULL | Estado de origen: A = activo, I = inactivo; sin CHECK en el DW |
| created_at | TIMESTAMP | Permite NULL | Fecha y hora de alta |

#### dim_channel

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| channel_key | INTEGER | PK | Clave subrogada del canal |
| channel_id | INTEGER | NOT NULL, UNIQUE | ID del canal en el origen |
| code | VARCHAR | Permite NULL | Código de origen: ONLINE u OFFLINE; sin CHECK en el DW |
| name | VARCHAR | Permite NULL | Nombre del canal |

#### dim_province

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| province_key | INTEGER | PK | Clave subrogada de la provincia |
| province_id | INTEGER | NOT NULL, UNIQUE | ID de la provincia en el origen |
| name | VARCHAR | Permite NULL | Nombre de la provincia |
| code | VARCHAR | Permite NULL | Código de la provincia |

El conjunto de datos contiene Buenos Aires, Córdoba, Santa Fe
y Mendoza.

#### dim_store

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| store_key | INTEGER | PK | Clave subrogada de la tienda |
| store_id | INTEGER | NOT NULL, UNIQUE | ID de la tienda en el origen |
| name | VARCHAR | Permite NULL | Nombre de la tienda |
| city | VARCHAR | Permite NULL | Ciudad de su dirección |
| province | VARCHAR | Permite NULL | Nombre de la provincia de la tienda |
| postal_code | VARCHAR | Permite NULL | Código postal; se conserva como texto |

La ubicación se incorpora desde raw.address y raw.province.
La columna province contiene un nombre, no una clave foránea.

#### dim_date

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| date_key | INTEGER | PK | Clave numérica AAAAMMDD; ejemplo: 20240131 |
| fecha | DATE | NOT NULL, UNIQUE | Día del calendario |
| anio | INTEGER | Permite NULL | Año de la fecha |
| mes | INTEGER | Permite NULL | Mes calculado, de 1 a 12 |
| dia | INTEGER | Permite NULL | Día del mes, de 1 a 31 según la fecha |
| trimestre | INTEGER | Permite NULL | Trimestre calculado, de 1 a 4 |

El calendario contiene una fila por día desde el 02/03/2023
hasta el 30/09/2025, inclusive. Las partes de la fecha se calculan
durante la carga; sus rangos no tienen restricciones CHECK.


### Diccionario de datos: hechos

FK significa clave foránea. Cuando tiene un valor distinto de NULL,
debe existir en la dimensión referenciada.

Las columnas sin NOT NULL ni PK permiten NULL.
Los importes DECIMAL(12,2) admiten 12 dígitos totales,
de los cuales 2 son decimales.

#### fact_order

Grano: un pedido.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| order_id | BIGINT | PK | ID del pedido de origen |
| customer_key | INTEGER | FK → dim_customer.customer_key; permite NULL | Cliente del pedido |
| channel_key | INTEGER | NOT NULL; FK → dim_channel.channel_key | Canal de venta |
| date_key | INTEGER | NOT NULL; FK → dim_date.date_key | Día del pedido |
| store_key | INTEGER | FK → dim_store.store_key; permite NULL | Tienda; NULL en pedidos online |
| province_key | INTEGER | FK → dim_province.province_key; permite NULL | Provincia de la dirección de envío |
| status | VARCHAR | Permite NULL | Estado de origen: CREATED, PAID, CANCELLED, FULFILLED o REFUNDED; sin CHECK en el DW |
| currency_code | VARCHAR | Permite NULL | Moneda; ARS en estos datos |
| subtotal | DECIMAL(12,2) | Permite NULL | Importe de productos después de descuentos, antes de IVA y envío |
| tax_amount | DECIMAL(12,2) | Permite NULL | Importe del IVA |
| shipping_fee | DECIMAL(12,2) | Permite NULL | Costo de envío |
| total_amount | DECIMAL(12,2) | Permite NULL | Subtotal más IVA y envío |

#### fact_order_item

Grano: una línea de producto dentro de un pedido.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| order_item_id | BIGINT | PK | ID de la línea de origen |
| order_id | BIGINT | NOT NULL | ID del pedido; sin FK declarada |
| product_key | INTEGER | NOT NULL; FK → dim_product.product_key | Producto vendido |
| customer_key | INTEGER | FK → dim_customer.customer_key; permite NULL | Cliente del pedido |
| channel_key | INTEGER | NOT NULL; FK → dim_channel.channel_key | Canal del pedido |
| date_key | INTEGER | NOT NULL; FK → dim_date.date_key | Día del pedido |
| store_key | INTEGER | FK → dim_store.store_key; permite NULL | Tienda del pedido |
| order_status | VARCHAR | Permite NULL | Estado del pedido; sin CHECK en el DW |
| quantity | INTEGER | NOT NULL; CHECK > 0 | Unidades de producto |
| unit_price | DECIMAL(12,2) | NOT NULL | Precio unitario aplicado a la venta |
| discount_amount | DECIMAL(12,2) | NOT NULL | Descuento total de la línea |
| line_total | DECIMAL(12,2) | NOT NULL | quantity × unit_price − discount_amount |

La fórmula de line_total proviene del origen. La carga copia
ese valor; no lo recalcula ni lo valida mediante un CHECK.

#### fact_payment

Grano: un registro de pago.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| payment_id | BIGINT | PK | ID del pago de origen |
| order_id | BIGINT | NOT NULL | ID del pedido; sin FK declarada |
| customer_key | INTEGER | FK → dim_customer.customer_key; permite NULL | Cliente del pedido |
| channel_key | INTEGER | NOT NULL; FK → dim_channel.channel_key | Canal del pedido |
| store_key | INTEGER | FK → dim_store.store_key; permite NULL | Tienda del pedido |
| payment_date_key | INTEGER | FK → dim_date.date_key; permite NULL | Día del pago, obtenido de paid_at |
| method | VARCHAR | NOT NULL; CHECK | CASH, CARD, TRANSFER o GATEWAY |
| status | VARCHAR | NOT NULL; CHECK | PENDING, PAID, FAILED o REFUNDED |
| amount | DECIMAL(12,2) | NOT NULL | Importe registrado en el pago |
| paid_at | TIMESTAMP | Permite NULL | Fecha y hora del pago |
| transaction_ref | VARCHAR | Permite NULL | Referencia de la transacción |

El conjunto de datos actual contiene un pago por pedido.
El DW no impone UNIQUE sobre order_id, por lo que admite
varios registros de pago para un mismo pedido.

#### fact_shipment

Grano: un envío.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| shipment_id | BIGINT | PK | ID del envío de origen |
| order_id | BIGINT | NOT NULL | ID del pedido; sin FK declarada |
| customer_key | INTEGER | FK → dim_customer.customer_key; permite NULL | Cliente del pedido |
| channel_key | INTEGER | NOT NULL; FK → dim_channel.channel_key | Canal del pedido |
| store_key | INTEGER | FK → dim_store.store_key; permite NULL | Tienda del pedido |
| shipped_date_key | INTEGER | FK → dim_date.date_key; permite NULL | Día de salida |
| delivered_date_key | INTEGER | FK → dim_date.date_key; permite NULL | Día de entrega |
| carrier | VARCHAR | Permite NULL | Transportista |
| tracking_number | VARCHAR | Permite NULL | Número de seguimiento |
| status | VARCHAR | NOT NULL; CHECK | READY, SHIPPED, DELIVERED o CANCELLED |
| shipped_at | TIMESTAMP | Permite NULL | Fecha y hora de salida |
| delivered_at | TIMESTAMP | Permite NULL | Fecha y hora de entrega |

La dimensión dim_date cumple dos roles en esta tabla:
fecha de salida y fecha de entrega.

#### fact_web_session

Grano: una sesión de navegación web.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| session_id | BIGINT | PK | ID de la sesión de origen |
| customer_key | INTEGER | FK → dim_customer.customer_key; permite NULL | Cliente identificado; NULL para sesiones anónimas |
| date_key | INTEGER | NOT NULL; FK → dim_date.date_key | Día de inicio de la sesión |
| started_at | TIMESTAMP | NOT NULL | Fecha y hora de inicio |
| ended_at | TIMESTAMP | Permite NULL | Fecha y hora de finalización |
| source | VARCHAR | Permite NULL | Origen de la visita: ads, direct, referral u organic en estos datos; sin CHECK |
| device | VARCHAR | Permite NULL | Dispositivo de navegación |

#### fact_nps_response

Grano: una respuesta a la encuesta NPS.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| nps_id | BIGINT | PK | ID de la respuesta de origen |
| customer_key | INTEGER | FK → dim_customer.customer_key; permite NULL | Cliente; puede ser anónimo |
| channel_key | INTEGER | NOT NULL; FK → dim_channel.channel_key | Canal asociado a la respuesta |
| date_key | INTEGER | NOT NULL; FK → dim_date.date_key | Día de respuesta |
| score | SMALLINT | NOT NULL; CHECK entre 0 y 10 | Puntaje de recomendación |
| comment | TEXT | Permite NULL | Comentario de la encuesta |
| responded_at | TIMESTAMP | NOT NULL | Fecha y hora de respuesta |

No contiene order_id porque el origen no identifica el pedido
al que corresponde la respuesta.

#### Identificador de pedido compartido

order_id permite reconocer el mismo pedido en hechos de pedidos,
ítems, pagos y envíos. En ítems, pagos y envíos se conserva como
identificador de negocio, sin una FK hacia fact_order.

No deben sumarse importes después de unir directamente hechos
con varias filas por pedido: esas uniones pueden duplicar valores.


### Consultas clave

Las consultas están en [sql/03_consultas.sql](sql/03_consultas.sql).
Se ejecutan con `python run_sql.py` y sus resultados se muestran
en la terminal.

| KPI | Tabla principal | Cálculo |
|---|---|---|
| Ventas | fact_order | SUM(total_amount), solo PAID y FULFILLED |
| Ticket promedio | fact_order | Ventas / cantidad de pedidos, con el mismo filtro |
| Usuarios activos | fact_web_session | Clientes distintos + sesiones anónimas del período |
| NPS | fact_nps_response | 100 × (promotores − detractores) / total de respuestas |
| Ventas por provincia | fact_order + dim_province | Ventas agrupadas por provincia |
| Ranking mensual por producto | fact_order_item + dim_product + dim_date | SUM(line_total) por mes y producto; puestos con DENSE_RANK |

También se incluyen ventas diarias, usuarios activos diarios
y NPS diario por canal para analizar su evolución temporal.

### Validaciones realizadas

- Las seis tablas de hechos conservaron la cantidad de filas
  de sus respectivas tablas de origen.
- Las sumas de importes de pedidos, ítems y pagos coinciden
  entre RAW y DW.
- No quedaron pedidos sin provincia en ninguno de los canales.
- Las ventas por provincia suman el mismo importe que las
  ventas totales.

Estas comprobaciones verifican cantidades, importes y cobertura
de provincias; no constituyen una validación exhaustiva de los datos.


### Diagrama del modelo estrella

El diagrama generado se encuentra en
[dw/modelo_estrella.md](dw/modelo_estrella.md).

Se actualiza al ejecutar `python run_sql.py`.

