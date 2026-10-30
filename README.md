# EcoBottle AR — Data warehouse y análisis comercial

Proyecto académico de Introducción al Marketing Online y los Negocios Digitales.

El objetivo es transformar los registros comerciales de EcoBottle AR en un modelo estrella, preparar indicadores mediante SQL y presentarlos en un dashboard para el área comercial.

Se analizan ventas, pedidos, ticket promedio, actividad web, NPS, distribución provincial y ranking mensual de productos.

**Dashboard publicado:** [EcoBottle en cifras](https://emma11284.github.io/practica-imond/docs/)

## Caso de negocio: del cliente al análisis comercial

EcoBottle AR es una empresa ficticia que vende botellas reutilizables Classic A y Sport B a través de su tienda online y de cuatro tiendas físicas ubicadas en Buenos Aires, Córdoba, Santa Fe y Mendoza.

El recorrido comercial comienza cuando un cliente realiza una compra. El pedido registra quién compra, por qué canal, en qué fecha y por qué importe. Su detalle identifica los productos, las cantidades, los precios y los descuentos aplicados.

Luego se registran los pagos asociados al pedido. Cuando la compra requiere envío, también se registra su seguimiento, desde la salida hasta la entrega.

La satisfacción se releva mediante encuestas NPS. Las respuestas disponibles identifican el canal y, cuando corresponde, el cliente, pero no permiten relacionarlas con un pedido específico.

En paralelo, las sesiones web permiten analizar la actividad digital. Una visita puede pertenecer a un cliente identificado o ser anónima y no implica necesariamente que se haya realizado una compra.

### Cómo se representa este recorrido en los datos

- Cliente y contexto de compra: dimensiones de cliente, producto, canal, tienda, provincia y fecha.
- Pedido: `fact_order`.
- Productos del pedido: `fact_order_item`.
- Pagos: `fact_payment`.
- Envíos: `fact_shipment`.
- Actividad digital: `fact_web_session`.
- Satisfacción: `fact_nps_response`.

Los CSV originales se conservan en `raw/`. Las transformaciones SQL construyen las dimensiones y los hechos del modelo estrella.

A partir de ese modelo se crean los data marts: tablas preparadas para los análisis del dashboard. El programa exporta las tablas como CSV a `dw/`.

La página web lee los marts y las dimensiones necesarias desde `dw/`; no consulta directamente los archivos de `raw/`.

## Origen y alcance de los datos

Los datos de muestra y el programa de ejecución provienen del [repositorio de la cátedra](https://github.com/AugustoCarmona/practica-imond).

- Empresa y datos ficticios, utilizados con fines académicos.
- Pedidos desde el **01/01/2024 hasta el 30/09/2025**.
- Importes expresados en pesos argentinos, ARS.
- Dos canales de venta: online y tiendas físicas.
- Cuatro provincias y dos productos.
- Los CSV de origen se conservan sin modificaciones.

El desarrollo de este fork incluye el modelo estrella, las transformaciones SQL, las consultas de KPIs, los controles de calidad, los data marts, el dashboard web y su documentación.

## Estructura del proyecto

| Ruta | Contenido |
|---|---|
| `raw/` | CSV originales del caso |
| `sql/01_dimensiones.sql` | Creación y carga de dimensiones |
| `sql/02_hechos.sql` | Creación y carga de hechos |
| `sql/03.1_KPIs.sql` | Consultas de los indicadores |
| `sql/03.2_verificaciones.sql` | Controles de carga y comparación entre RAW y DW |
| `sql/04_marts.sql` | Tablas de resultados para el dashboard |
| `run_sql.py` | Programa de ejecución y exportación provisto por la cátedra |
| `requirements.txt` | Dependencias de Python |
| `dw/` | CSV del modelo estrella, marts y diagrama generado |
| `docs/index.html` | Contenido y estructura del dashboard |
| `docs/styles.css` | Estilos del dashboard |
| `docs/app.js` | Lectura de CSV, filtros y gráficos |
| `docs/logo.png` | Logo de EcoBottle |
| `assets/` | Diagrama de las tablas de origen |
| `generator/` | Generador de datos de muestra; no es necesario para ejecutar el proyecto |

La presentación principal del trabajo es el dashboard web publicado en GitHub Pages.

## Instrucciones de ejecución

### Requisitos

- Git.
- Python 3.9 o superior.
- Navegador web.
- Conexión a Internet para clonar el repositorio e instalar las dependencias.

No se necesita instalar un servidor de bases de datos: el proyecto utiliza DuckDB.

### Instalación local en Windows — CMD

```bat
git clone https://github.com/emma11284/practica-imond.git
cd practica-imond
python -m venv .venv
.venv\Scripts\activate.bat
python -m pip install -r requirements.txt
```

Cada vez que se abre una terminal nueva, se debe ingresar a la carpeta del proyecto y activar nuevamente el entorno:

```bat
.venv\Scripts\activate.bat
```

### Instalación local en macOS — Terminal

Requisitos: Git y Python 3 instalados.

```bash
git clone https://github.com/emma11284/practica-imond.git
cd practica-imond
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
```

En cada terminal nueva, ingresar a la carpeta del proyecto y activar el entorno:

```bash
source .venv/bin/activate
```

El entorno `.venv` no se incorpora al repositorio. Las dependencias se instalan mediante `requirements.txt`.

### Construcción del data warehouse

Desde la carpeta principal del proyecto:

```bat
python run_sql.py
```

El programa:

1. Reconstruye `warehouse.duckdb`.
2. Carga los CSV de `raw/` en el esquema `raw`.
3. Ejecuta los archivos de `sql/` en orden alfabético.
4. Muestra los resultados de las consultas en la terminal.
5. Exporta las tablas del modelo y los marts como CSV a `dw/`.
6. Genera `dw/modelo_estrella.md`.

La ejecución reconstruye la base y regenera los CSV de salida; no realiza una carga incremental.

`warehouse.duckdb` se excluye de Git porque puede reconstruirse. Los CSV de `dw/` se incorporan al repositorio para que el dashboard publicado pueda leerlos.

### Dashboard publicado

[Acceder a EcoBottle en cifras](https://emma11284.github.io/practica-imond/docs/)

La versión publicada no necesita Python, DuckDB ni una terminal abierta.

GitHub Pages publica desde la rama `main` y la raíz del repositorio. Esto permite acceder tanto a `docs/` como a `dw/`, manteniendo la ruta relativa utilizada por la página.

El enlace del dashboard termina en `/docs/`. La dirección raíz del sitio puede mostrar el README.


### Abrir el dashboard localmente

Desde la carpeta principal del proyecto, ejecutar:

```bat
python -m http.server 8000
```

Abrir en el navegador:

[http://localhost:8000/docs/](http://localhost:8000/docs/)

La terminal debe permanecer abierta mientras se consulta esta versión local. Para detener el servidor, presionar `Ctrl + C`.

Se utiliza un servidor local para que JavaScript pueda solicitar los archivos CSV. No se debe abrir `index.html` directamente mediante doble clic.


### Actualización de los datos publicados

1. Incorporar los cambios de origen o de las transformaciones que correspondan.
2. Ejecutar `python run_sql.py`.
3. Revisar los resultados y los controles de calidad.
4. Incorporar a Git los scripts y CSV modificados.
5. Crear el commit y ejecutar `git push`.

GitHub Pages actualiza la publicación a partir de los archivos subidos. No ejecuta Python ni SQL: muestra los CSV incluidos en el repositorio.

### Exploración opcional

Para explorar únicamente las tablas de origen:

```bat
python run_sql.py --explorar
```

Para construir el DW y abrir la interfaz de exploración:

```bat
python run_sql.py --ui
```

Estos modos permiten inspeccionar los datos y el modelo. No son necesarios para consultar el dashboard publicado.

## Modelo estrella

### Dimensiones

Las dimensiones describen el contexto utilizado para analizar los hechos.

| Tabla | Qué describe | Clave primaria |
|---|---|---|
| `dim_product` | Productos, categorías y familias | `product_key` |
| `dim_customer` | Clientes | `customer_key` |
| `dim_channel` | Canales de venta | `channel_key` |
| `dim_province` | Provincias | `province_key` |
| `dim_store` | Tiendas y ubicación | `store_key` |
| `dim_date` | Calendario: fecha, año, mes, día y trimestre | `date_key` |

### Hechos y grano

El grano indica qué representa una fila.

| Tabla | Qué representa una fila | Clave primaria |
|---|---|---|
| `fact_order` | Un pedido | `order_id` |
| `fact_order_item` | Una línea de producto dentro de un pedido | `order_item_id` |
| `fact_payment` | Un registro de pago | `payment_id` |
| `fact_shipment` | Un envío | `shipment_id` |
| `fact_web_session` | Una sesión de navegación web | `session_id` |
| `fact_nps_response` | Una respuesta a la encuesta NPS | `nps_id` |

### Claves y relaciones

Las tablas de hechos se relacionan con las dimensiones mediante claves foráneas. Por ejemplo:

`fact_order_item.product_key` → `dim_product.product_key`.

Las claves naturales, como `product_id`, conservan el identificador del sistema de origen. Las claves subrogadas, como `product_key`, se generan en el DW.

Las claves subrogadas de producto, cliente, canal, provincia y tienda se generan con `ROW_NUMBER()`, ordenando por el ID de origen. Se recalculan en cada reconstrucción; no se garantiza su estabilidad si cambia el conjunto de IDs.

`date_key` se construye a partir de la fecha con el formato numérico `AAAAMMDD`.

`order_id` permite reconocer el mismo pedido en los hechos de pedidos, ítems, pagos y envíos. En ítems, pagos y envíos se conserva como identificador de negocio, sin una FK declarada hacia `fact_order`.

No deben sumarse totales de pedidos después de unirlos directamente con tablas que tienen varias filas por pedido, porque pueden duplicarse los importes.

El mart de productos une cada ítem con su pedido para obtener la provincia y aplicar el estado válido; suma el importe de las líneas, no el total de la cabecera.

### Diagrama

[Ver el modelo estrella](dw/modelo_estrella.md).

Se regenera al ejecutar `python run_sql.py`. Puede verse en GitHub o en VS Code con la extensión Markdown Preview Mermaid Support y la vista previa de Markdown.

## Data marts

Los marts se crean en [sql/04_marts.sql](sql/04_marts.sql), a partir del modelo estrella o de otro mart derivado de ese modelo. No leen directamente RAW.

| Mart | Grano o combinación representada | Resultados |
|---|---|---|
| `mart_ventas_diarias` | Día, canal y provincia | Pedidos válidos y tres variantes de importe de ventas |
| `mart_ventas_producto_diarias` | Día, producto, canal y provincia | Unidades vendidas e importe neto de las líneas |
| `mart_ticket_periodos` | Período, canal y provincia, incluyendo agrupaciones generales | Pedidos, ventas y ticket promedio |
| `mart_nps_periodos` | Período y canal, incluyendo agrupaciones generales | Respuestas, categorías, porcentajes y NPS |
| `mart_usuarios_periodos` | Cada mes y todo el período | Clientes identificados distintos, sesiones anónimas e indicador combinado |
| `mart_sesiones_fuente_diarias` | Día y fuente de tráfico | Cantidad de sesiones |

`mart_ticket_periodos` se calcula desde `mart_ventas_diarias`, relacionándolo con las dimensiones necesarias.

`mart_sesiones_fuente_diarias` está disponible para análisis adicionales, aunque no se utiliza en la versión actual del dashboard web.

### Totales y subtotales

Los marts de ticket y NPS contienen filas para cada mes y para todo el período, además de agrupaciones de canales y provincias cuando corresponden.

La página selecciona la fila que coincide con los filtros. No suma las filas generales con sus desgloses.

El ticket de varios días se calcula en SQL como ventas acumuladas divididas por pedidos acumulados. No se promedian los tickets diarios.

Los usuarios activos de todo el período se calculan directamente sobre las sesiones de todo ese período. No se suman los usuarios mensuales, porque un mismo cliente puede aparecer en varios meses.

El NPS general se calcula con todas las respuestas del período. No se promedian los NPS mensuales.

## Indicadores y reglas de negocio

El reporte está dirigido al área comercial. Los indicadores permiten observar el desempeño; no se establecieron metas ni umbrales propios de éxito o fracaso para la empresa ficticia.

### Definiciones de los seis KPIs

| Indicador | Cálculo | Fecha utilizada | Unidad y presentación |
|---|---|---|---|
| Ventas | Suma de `total_amount` para pedidos `PAID` o `FULFILLED`; el selector permite consultar otras variantes del importe | Fecha del pedido | ARS; tarjeta y gráficos en millones, M |
| Ticket promedio | Ventas con IVA y envío / cantidad de pedidos válidos | Fecha del pedido | ARS por pedido; tarjeta en miles |
| Usuarios activos | Clientes identificados distintos + cantidad de sesiones anónimas del período | Inicio de la sesión | Indicador combinado de actividad; se muestra el valor completo |
| NPS | `100 × (promotores − detractores) / total de respuestas` | Fecha de respuesta | Puntos, de −100 a 100 |
| Ventas por provincia | Ventas de pedidos válidos agrupadas por provincia de envío | Fecha del pedido | ARS; presentación en millones |
| Ranking mensual por producto | Suma de `line_total` de pedidos válidos, por mes y producto | Fecha del pedido | ARS sin IVA ni envío; presentación en millones |

La página permite consultar un mes completo o todo el período. Las tendencias se presentan por mes.

Los pedidos vendidos se muestran como indicador adicional y cuentan los pedidos `PAID` o `FULFILLED`.

### Importes de ventas

| Opción | Cálculo |
|---|---|
| Con IVA y envío | `SUM(total_amount)` |
| Con IVA, sin envío | `SUM(total_amount - shipping_fee)` |
| Sin IVA ni envío | `SUM(subtotal)` |

El selector modifica la tarjeta de Ventas, la serie mensual de ventas y la comparación provincial.

El ticket conserva siempre IVA y envío. El ranking utiliza importes de líneas después del descuento, sin IVA ni envío.

Por eso, si se cambia la opción de importe, la tarjeta de ventas puede dejar de ser el numerador utilizado por el ticket mostrado. Esta diferencia está indicada en las aclaraciones del dashboard.

### Estados incluidos

Ventas, pedidos vendidos, ticket y ranking consideran únicamente pedidos con estado `PAID` o `FULFILLED`.

Los demás estados se conservan en las tablas de hechos, pero no se incluyen en esos indicadores.

### Provincia

La provincia de venta se obtiene de:

`shipping_address_id` → `raw.address.province_id` → `dim_province`.

Representa la provincia asociada a la dirección de envío. En los datos offline, se utiliza la dirección de la tienda según la convención del conjunto de origen.

No se interpreta automáticamente como provincia de residencia del cliente.

### Usuarios activos: criterio adoptado

Se conserva el indicador combinado permitido por la consigna:

- Cada cliente identificado cuenta una vez dentro del período.
- Cada sesión sin cliente identificado cuenta como una unidad adicional.

**No representa personas únicas.** Una persona puede generar varias sesiones anónimas o aparecer como identificada en otro momento.

El mart conserva por separado `clientes_identificados` y `sesiones_anonimas`, además del total combinado. El dashboard incorpora una aclaración visible sobre su interpretación.

### NPS

- Promotores: puntajes 9 y 10.
- Pasivos: puntajes 7 y 8.
- Detractores: puntajes de 0 a 6.
- Los pasivos se incluyen en el denominador.
- El NPS se expresa en puntos, no como una nota de 0 a 10.

Un NPS de 30 significa que el porcentaje de promotores supera al de detractores en aproximadamente 30 puntos porcentuales. No significa que el 30 % de todos los clientes esté satisfecho.

### Fechas y datos opcionales

- Se conservan los timestamps de origen sin conversión de zona horaria; para agrupar se utiliza el día registrado.
- El calendario abarca del 01/01/2024 al 30/09/2025, inclusive.
- Si se incorporan eventos fuera de ese rango, debe ampliarse el calendario y comprobarse su asignación.
- Se conservan los `NULL` de datos opcionales: clientes anónimos, tiendas en pedidos online y fechas de eventos todavía no ocurridos.
- El modelo no implementa versiones históricas de las dimensiones.

## Dashboard y alcance de los filtros

El dashboard contiene:

1. Panorama general: tarjetas de indicadores.
2. Ventas y territorio: ventas mensuales y comparación de provincias.
3. Productos: ranking por importe vendido.
4. Actividad digital: evolución mensual del indicador de usuarios activos.
5. Opinión de clientes: NPS mensual y distribución de respuestas.
6. Detrás de los datos: explicación de la arquitectura.

### Matriz de filtros

| Selección | Ventas y pedidos | Ticket | Ranking de productos | Usuarios activos | NPS y distribución |
|---|---|---|---|---|---|
| Período | Sí | Sí | Sí | Sí | Sí |
| Canal | Sí | Sí | Sí | No | Sí |
| Provincia | Sí | Sí | Sí | No | No |
| Producto | No | No | Sí | No | No |
| Importe de ventas | Ventas y sus gráficos; no cambia el conteo de pedidos | No | No | No | No |

El producto filtra el ranking, no los importes de pedidos completos. No se distribuyen impuestos y envío entre productos.

Las sesiones web no contienen canal de venta, provincia ni producto. Las encuestas NPS no contienen provincia ni producto. No se atribuyen esas dimensiones a los registros mediante relaciones supuestas con otras compras del cliente.

El botón **Restablecer filtros** vuelve a todo el período, todos los canales, provincias y productos, y ventas con IVA y envío.

### Responsabilidad de SQL y JavaScript

SQL construye el modelo, los marts y los resultados de ticket, usuarios y NPS.

JavaScript:

- Lee los CSV de `dw/`.
- Aplica los filtros.
- Selecciona los resultados precalculados.
- Suma importes y cantidades aditivas de los marts diarios.
- Ordena los productos por importe.
- Dibuja los gráficos y presenta los valores.

El dashboard no ejecuta consultas sobre RAW ni recalcula el NPS o los clientes distintos.

## Consultas clave

Las consultas se encuentran en [sql/03.1_KPIs.sql](sql/03.1_KPIs.sql).

Incluyen los seis indicadores, el ranking mensual con `DENSE_RANK`, ventas diarias, actividad web diaria y NPS diario por canal.

Ejemplo de ventas y ticket desde el modelo estrella:

```sql
SELECT
    COUNT(*) AS pedidos_vendidos,
    SUM(total_amount) AS ventas_totales,
    SUM(total_amount) / NULLIF(COUNT(*), 0) AS ticket_promedio
FROM fact_order
WHERE status IN ('PAID', 'FULFILLED');
```

Ejemplo de consulta del NPS general ya preparado:

```sql
SELECT
    total_respuestas,
    promotores,
    pasivos,
    detractores,
    nps
FROM mart_nps_periodos
WHERE periodo = 'Todo el período'
  AND canal = 'Todos los canales';
```

La primera consulta utiliza el modelo estrella. La segunda consulta un resultado del mart.

## Validaciones de carga y consistencia

Las consultas de control están en [sql/03.2_verificaciones.sql](sql/03.2_verificaciones.sql).

Se ejecutan con:

```bat
python run_sql.py
```

### Controles implementados

| Control | Qué comprueba | Resultado esperado |
|---|---|---|
| Correspondencia de identificadores | Registros de RAW que faltan en DW y registros de DW sin identificador de origen, en los seis hechos | 0 faltantes y 0 registros sin origen |
| Importes acumulados | Sumas de pedidos, ítems y pagos entre RAW y DW | Importes iguales |
| Importes individuales de pedidos | Subtotal, impuestos, envío y total de cada pedido frente a RAW | 0 diferencias |
| Importe con IVA y sin envío | Columna calculada frente a `total_amount - shipping_fee` de origen | 0 diferencias |
| Composición del total | Total igual a subtotal más impuestos y envío; componentes no nulos | 0 inconsistencias |
| Importe de líneas | `line_total = quantity × unit_price - discount_amount`; componentes no nulos | 0 inconsistencias |
| Conciliación de pedidos e ítems | Pedidos sin líneas y subtotal frente a suma de sus líneas | 0 pedidos sin ítems y 0 diferencias |
| Asignación de dimensiones en pedidos | Datos presentes en RAW que quedaron sin clave en DW | 0 asignaciones perdidas |
| Clientes de sesiones y NPS | Clientes identificados en RAW que quedaron sin asignar | 0 asignaciones perdidas |
| Fechas de pedidos, sesiones y NPS | Día de la dimensión frente al evento de origen | 0 diferencias |
| Puntajes NPS | Puntaje de cada respuesta frente a RAW | 0 diferencias |
| KPIs entre RAW y DW | Ventas, pedidos, ticket, componentes de actividad web, NPS, provincias y ranking mensual | Coincidencia bajo las mismas reglas |

Las restricciones `PRIMARY KEY` impiden claves primarias duplicadas o nulas. Las `FOREIGN KEY` declaradas impiden cargar claves no nulas inexistentes en la dimensión correspondiente.

Estas restricciones no detectan por sí solas una relación asignada a la fila equivocada ni una clave opcional perdida durante un `LEFT JOIN`; por eso se complementan con consultas de control.

### Interpretación de valores vacíos

Un pedido online puede no tener tienda y una sesión o respuesta NPS puede no tener cliente identificado. Estos casos no son errores por sí mismos.

Un dato presente en RAW que se pierde durante la carga sí requiere revisión.

La consulta de pedidos sin provincia presenta los casos por canal. Debe interpretarse según la disponibilidad de la dirección de envío.

### Resultados y alcance

En las ejecuciones revisadas, los controles de diferencias y registros faltantes devolvieron 0 incidencias. Los importes comparados entre RAW y DW coincidieron.

La comparación del ranking mensual comprobó las 42 combinaciones de mes y producto del conjunto.

También se revisó el dashboard con:

- Todo el período y sin filtros.
- Canal Tiendas Físicas.
- Provincia Córdoba.
- Enero de 2025.
- Producto Classic A.
- Importe sin IVA ni envío.
- Restablecimiento de filtros y navegación por secciones.

Los valores generales y los casos contrastados coincidieron con los resultados disponibles en SQL.

Estas comprobaciones cubren las reglas detalladas. No certifican la exactitud del sistema de origen ni constituyen una auditoría exhaustiva de todos los campos y combinaciones de filtros.


## Limitaciones e interpretación responsable

- Los datos son ficticios y no permiten generalizar resultados a una empresa real.
- El período termina en septiembre de 2025: no corresponde comparar todo 2024 con todo 2025 como si ambos fueran años completos.
- Los importes son nominales: no se ajustan por inflación.
- No se dispone de costos para calcular margen o rentabilidad.
- No se puede reconstruir una conversión individual de visita a compra con las relaciones disponibles.
- El indicador combinado de actividad no representa personas únicas.
- El NPS describe a quienes respondieron, no necesariamente a toda la clientela.
- El calendario y las claves subrogadas deben revisarse si cambia el conjunto de origen.
- Los datos de ticket, usuarios y NPS están preparados para meses completos y todo el período; la página no ofrece intervalos arbitrarios de días.
- Los resultados agregados de los marts no deben sumarse junto con sus subtotales.


## Diccionario de datos

### Convenciones

- **PK:** clave primaria; identifica una fila, no admite duplicados ni `NULL`.
- **FK:** clave foránea; si tiene un valor no nulo, debe existir en la tabla referenciada.
- **NOT NULL:** dato obligatorio.
- **UNIQUE:** valor no repetido.
- **CHECK:** restricción sobre los valores permitidos.
- Las columnas sin PK ni `NOT NULL` permiten `NULL`.
- `DECIMAL(12,2)` admite 12 dígitos totales, incluidos 2 decimales.
- Los dominios descriptos como “de origen” no implican un `CHECK` en el DW.

### Dimensiones

#### dim_product

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| product_key | INTEGER | PK | Clave subrogada |
| product_id | INTEGER | NOT NULL | ID de origen |
| sku | VARCHAR | NOT NULL | Código comercial |
| name | VARCHAR | NOT NULL | Nombre |
| category | VARCHAR | Permite NULL | Categoría: Classic o Sport en estos datos |
| family | VARCHAR | Permite NULL | Categoría padre: Bottles en estos datos |
| list_price | DECIMAL(12,2) | Permite NULL | Precio de lista en ARS |

La categoría y su familia se incorporan a la fila del producto mediante uniones con `raw.product_category`.

#### dim_customer

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| customer_key | INTEGER | PK | Clave subrogada |
| customer_id | INTEGER | NOT NULL, UNIQUE | ID de origen |
| email | VARCHAR | Permite NULL | Correo |
| first_name | VARCHAR | Permite NULL | Nombre |
| last_name | VARCHAR | Permite NULL | Apellido |
| phone | VARCHAR | Permite NULL | Teléfono |
| status | VARCHAR | Permite NULL | Estado de origen: A o I; sin CHECK |
| created_at | TIMESTAMP | Permite NULL | Fecha y hora de alta |

#### dim_channel

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| channel_key | INTEGER | PK | Clave subrogada |
| channel_id | INTEGER | NOT NULL, UNIQUE | ID de origen |
| code | VARCHAR | Permite NULL | ONLINE u OFFLINE en origen; sin CHECK |
| name | VARCHAR | Permite NULL | Nombre del canal |

#### dim_province

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| province_key | INTEGER | PK | Clave subrogada |
| province_id | INTEGER | NOT NULL, UNIQUE | ID de origen |
| name | VARCHAR | Permite NULL | Nombre |
| code | VARCHAR | Permite NULL | Código |

El conjunto contiene Buenos Aires, Córdoba, Santa Fe y Mendoza.

#### dim_store

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| store_key | INTEGER | PK | Clave subrogada |
| store_id | INTEGER | NOT NULL, UNIQUE | ID de origen |
| name | VARCHAR | Permite NULL | Nombre |
| city | VARCHAR | Permite NULL | Ciudad |
| province | VARCHAR | Permite NULL | Nombre de provincia; no es una FK |
| postal_code | VARCHAR | Permite NULL | Código postal conservado como texto |

La ubicación se incorpora desde `raw.address` y `raw.province`.

#### dim_date

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| date_key | INTEGER | PK | Fecha numérica AAAAMMDD |
| fecha | DATE | NOT NULL, UNIQUE | Día del calendario |
| anio | INTEGER | Permite NULL | Año |
| mes | INTEGER | Permite NULL | Mes calculado: 1–12 |
| dia | INTEGER | Permite NULL | Día calculado según la fecha |
| trimestre | INTEGER | Permite NULL | Trimestre calculado: 1–4 |

Contiene una fila por día del 01/01/2024 al 30/09/2025, inclusive. Las partes de la fecha se calculan durante la carga, sin restricciones CHECK adicionales.

### Hechos

#### fact_order

Grano: un pedido.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| order_id | BIGINT | PK | ID del pedido |
| customer_key | INTEGER | FK → dim_customer; permite NULL | Cliente |
| channel_key | INTEGER | NOT NULL; FK → dim_channel | Canal |
| date_key | INTEGER | NOT NULL; FK → dim_date | Día del pedido |
| store_key | INTEGER | FK → dim_store; permite NULL | Tienda |
| province_key | INTEGER | FK → dim_province; permite NULL | Provincia de envío |
| status | VARCHAR | Permite NULL | CREATED, PAID, CANCELLED, FULFILLED o REFUNDED de origen; sin CHECK |
| currency_code | VARCHAR | Permite NULL | Moneda; ARS en estos datos |
| subtotal | DECIMAL(12,2) | Permite NULL | Productos después de descuentos, antes de IVA y envío |
| tax_amount | DECIMAL(12,2) | Permite NULL | IVA |
| shipping_fee | DECIMAL(12,2) | Permite NULL | Envío |
| total_amount | DECIMAL(12,2) | Permite NULL | Subtotal más IVA y envío |
| amount_with_tax_without_shipping | DECIMAL(12,2) | Permite NULL | `total_amount - shipping_fee`, calculado en SQL |

#### fact_order_item

Grano: una línea de producto de un pedido.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| order_item_id | BIGINT | PK | ID de la línea |
| order_id | BIGINT | NOT NULL; sin FK declarada | Pedido |
| product_key | INTEGER | NOT NULL; FK → dim_product | Producto |
| customer_key | INTEGER | FK → dim_customer; permite NULL | Cliente |
| channel_key | INTEGER | NOT NULL; FK → dim_channel | Canal |
| date_key | INTEGER | NOT NULL; FK → dim_date | Día del pedido |
| store_key | INTEGER | FK → dim_store; permite NULL | Tienda |
| order_status | VARCHAR | Permite NULL | Estado del pedido; sin CHECK |
| quantity | INTEGER | NOT NULL; CHECK > 0 | Unidades |
| unit_price | DECIMAL(12,2) | NOT NULL | Precio unitario aplicado |
| discount_amount | DECIMAL(12,2) | NOT NULL | Descuento total de la línea |
| line_total | DECIMAL(12,2) | NOT NULL | `quantity × unit_price - discount_amount` |

`line_total` se copia del origen. Su fórmula se verifica mediante consultas; no se impone como CHECK en esta tabla.

#### fact_payment

Grano: un registro de pago.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| payment_id | BIGINT | PK | ID del pago |
| order_id | BIGINT | NOT NULL; sin FK declarada | Pedido |
| customer_key | INTEGER | FK → dim_customer; permite NULL | Cliente |
| channel_key | INTEGER | NOT NULL; FK → dim_channel | Canal |
| store_key | INTEGER | FK → dim_store; permite NULL | Tienda |
| payment_date_key | INTEGER | FK → dim_date; permite NULL | Día de `paid_at` |
| method | VARCHAR | NOT NULL; CHECK | CASH, CARD, TRANSFER o GATEWAY |
| status | VARCHAR | NOT NULL; CHECK | PENDING, PAID, FAILED o REFUNDED |
| amount | DECIMAL(12,2) | NOT NULL | Importe |
| paid_at | TIMESTAMP | Permite NULL | Fecha y hora del pago |
| transaction_ref | VARCHAR | Permite NULL | Referencia de transacción |

No se declara UNIQUE sobre `order_id`: la estructura admite varios pagos por pedido.

#### fact_shipment

Grano: un envío.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| shipment_id | BIGINT | PK | ID del envío |
| order_id | BIGINT | NOT NULL; sin FK declarada | Pedido |
| customer_key | INTEGER | FK → dim_customer; permite NULL | Cliente |
| channel_key | INTEGER | NOT NULL; FK → dim_channel | Canal |
| store_key | INTEGER | FK → dim_store; permite NULL | Tienda |
| shipped_date_key | INTEGER | FK → dim_date; permite NULL | Día de salida |
| delivered_date_key | INTEGER | FK → dim_date; permite NULL | Día de entrega |
| carrier | VARCHAR | Permite NULL | Transportista |
| tracking_number | VARCHAR | Permite NULL | Seguimiento |
| status | VARCHAR | NOT NULL; CHECK | READY, SHIPPED, DELIVERED o CANCELLED |
| shipped_at | TIMESTAMP | Permite NULL | Fecha y hora de salida |
| delivered_at | TIMESTAMP | Permite NULL | Fecha y hora de entrega |

`dim_date` cumple dos roles: fecha de salida y fecha de entrega.

#### fact_web_session

Grano: una sesión de navegación web.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| session_id | BIGINT | PK | ID de la sesión |
| customer_key | INTEGER | FK → dim_customer; permite NULL | Cliente; NULL si es anónima |
| date_key | INTEGER | NOT NULL; FK → dim_date | Día de inicio |
| started_at | TIMESTAMP | NOT NULL | Fecha y hora de inicio |
| ended_at | TIMESTAMP | Permite NULL | Fecha y hora de finalización |
| source | VARCHAR | Permite NULL | Fuente de tráfico; sin CHECK |
| device | VARCHAR | Permite NULL | Dispositivo |

#### fact_nps_response

Grano: una respuesta NPS.

| Columna | Tipo | Restricciones | Significado / dominio |
|---|---|---|---|
| nps_id | BIGINT | PK | ID de la respuesta |
| customer_key | INTEGER | FK → dim_customer; permite NULL | Cliente |
| channel_key | INTEGER | NOT NULL; FK → dim_channel | Canal |
| date_key | INTEGER | NOT NULL; FK → dim_date | Día de respuesta |
| score | SMALLINT | NOT NULL; CHECK 0–10 | Puntaje |
| comment | TEXT | Permite NULL | Comentario |
| responded_at | TIMESTAMP | NOT NULL | Fecha y hora de respuesta |

No contiene `order_id` porque el origen no identifica el pedido de la respuesta.

### Campos de los marts

Los marts se crean mediante `CREATE TABLE ... AS SELECT`. No declaran PK ni FK adicionales: su grano describe la combinación que debe identificar cada resultado.

| Mart | Campos |
|---|---|
| `mart_ventas_diarias` | `date_key`, `channel_key`, `province_key`, `pedidos_vendidos`, `ventas_con_iva_y_envio`, `ventas_con_iva_sin_envio`, `ventas_sin_iva_ni_envio` |
| `mart_ventas_producto_diarias` | `date_key`, `product_key`, `channel_key`, `province_key`, `unidades_vendidas`, `ventas_producto` |
| `mart_ticket_periodos` | `periodo`, `canal`, `provincia`, `pedidos_vendidos`, `ventas_totales`, `ticket_promedio` |
| `mart_nps_periodos` | `periodo`, `canal`, `anio`, `numero_mes`, `nombre_mes`, `total_respuestas`, `promotores`, `pasivos`, `detractores`, `porcentaje_promotores`, `porcentaje_pasivos`, `porcentaje_detractores`, `nps` |
| `mart_usuarios_periodos` | `periodo`, `anio`, `numero_mes`, `nombre_mes`, `clientes_identificados`, `sesiones_anonimas`, `usuarios_activos` |
| `mart_sesiones_fuente_diarias` | `date_key`, `fuente`, `cantidad_sesiones` |

Convenciones:

- `periodo`: `AAAA-MM` o `Todo el período`.
- `canal`: nombre del canal o `Todos los canales`.
- `provincia`: nombre de provincia o `Todas las provincias`; puede ser NULL si falta la asignación de origen.
- En las filas de todo el período, las partes del mes pueden ser NULL.
- Los porcentajes NPS se expresan de 0 a 100.
- Los importes se conservan en ARS; la conversión a millones o miles se realiza solo para presentarlos.
- `nps` y `ticket_promedio` no deben sumarse.
- `usuarios_activos` no es aditivo entre meses.

## Gestión del repositorio

La gestión de Git se realiza desde la consola.

Los commits utilizan Conventional Commits, con mensajes que describen el cambio, por ejemplo:

- `feat: incorporar marts para el dashboard`
- `fix: corregir navegación al inicio`
- `docs: actualizar reglas de cálculo y ejecución`

Antes de cada commit se revisan `git status` y los cambios correspondientes. Se agregan los archivos relacionados con el avance, evitando incorporar el entorno virtual, bases regenerables y copias personales.

Los CSV de `dw/` se versionan porque son la fuente de la página publicada.

## Referencias

- [Repositorio de la cátedra](https://github.com/AugustoCarmona/practica-imond).
- [Apunte incorporado por la cátedra](https://github.com/AugustoCarmona/practica-imond/pull/1).
- [Repositorio de este proyecto](https://github.com/emma11284/practica-imond).
- [Dashboard EcoBottle en cifras](https://emma11284.github.io/practica-imond/docs/).