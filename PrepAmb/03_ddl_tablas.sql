-- Tablas delta externas de cada capa (ejemplo con catalog_dev).
-- Para produccion se cambia catalog_dev por catalog_prod.
-- El notebook proceso/01_prep_ambiente crea estas mismas tablas.

-- bronze
CREATE TABLE IF NOT EXISTS catalog_dev.bronze.orders (
  order_id INT, user_id INT, eval_set STRING, order_number INT, order_dow INT,
  order_hour_of_day INT, days_since_prior_order DOUBLE,
  ingestion_date TIMESTAMP, source_file STRING)
USING DELTA
LOCATION 'abfss://bronze@<storage_account>.dfs.core.windows.net/catalog_dev/orders';

CREATE TABLE IF NOT EXISTS catalog_dev.bronze.order_products (
  order_id INT, product_id INT, add_to_cart_order INT, reordered INT, eval_set STRING,
  ingestion_date TIMESTAMP, source_file STRING)
USING DELTA
LOCATION 'abfss://bronze@<storage_account>.dfs.core.windows.net/catalog_dev/order_products';

CREATE TABLE IF NOT EXISTS catalog_dev.bronze.products (
  product_id INT, product_name STRING, aisle_id INT, department_id INT,
  ingestion_date TIMESTAMP, source_file STRING)
USING DELTA
LOCATION 'abfss://bronze@<storage_account>.dfs.core.windows.net/catalog_dev/products';

CREATE TABLE IF NOT EXISTS catalog_dev.bronze.aisles (
  aisle_id INT, aisle STRING, ingestion_date TIMESTAMP, source_file STRING)
USING DELTA
LOCATION 'abfss://bronze@<storage_account>.dfs.core.windows.net/catalog_dev/aisles';

CREATE TABLE IF NOT EXISTS catalog_dev.bronze.departments (
  department_id INT, department STRING, ingestion_date TIMESTAMP, source_file STRING)
USING DELTA
LOCATION 'abfss://bronze@<storage_account>.dfs.core.windows.net/catalog_dev/departments';

-- silver
CREATE TABLE IF NOT EXISTS catalog_dev.silver.productos (
  product_id INT, nombre_producto STRING, aisle_id INT, pasillo STRING,
  department_id INT, departamento STRING, es_organico BOOLEAN, fecha_proceso TIMESTAMP)
USING DELTA
LOCATION 'abfss://silver@<storage_account>.dfs.core.windows.net/catalog_dev/productos';

CREATE TABLE IF NOT EXISTS catalog_dev.silver.ordenes (
  order_id INT, user_id INT, eval_set STRING, numero_orden INT, dia_semana_num INT,
  dia_semana STRING, hora_dia INT, franja_horaria STRING, dias_desde_orden_previa INT,
  es_primera_orden BOOLEAN, fecha_proceso TIMESTAMP)
USING DELTA
LOCATION 'abfss://silver@<storage_account>.dfs.core.windows.net/catalog_dev/ordenes';

CREATE TABLE IF NOT EXISTS catalog_dev.silver.detalle_ordenes (
  order_id INT, product_id INT, user_id INT, orden_en_carrito INT, es_recompra BOOLEAN,
  nombre_producto STRING, pasillo STRING, departamento STRING, es_organico BOOLEAN,
  numero_orden INT, dia_semana_num INT, dia_semana STRING, hora_dia INT, franja_horaria STRING,
  fecha_proceso TIMESTAMP)
USING DELTA
PARTITIONED BY (departamento)
LOCATION 'abfss://silver@<storage_account>.dfs.core.windows.net/catalog_dev/detalle_ordenes';

-- golden
CREATE TABLE IF NOT EXISTS catalog_dev.golden.kpi_departamentos (
  departamento STRING, total_productos_vendidos BIGINT, total_ordenes BIGINT,
  total_clientes BIGINT, productos_distintos BIGINT, tasa_recompra DOUBLE,
  participacion_pct DOUBLE, fecha_proceso TIMESTAMP)
USING DELTA
LOCATION 'abfss://golden@<storage_account>.dfs.core.windows.net/catalog_dev/kpi_departamentos';

CREATE TABLE IF NOT EXISTS catalog_dev.golden.top_productos (
  departamento STRING, ranking INT, nombre_producto STRING, veces_comprado BIGINT,
  tasa_recompra DOUBLE, fecha_proceso TIMESTAMP)
USING DELTA
LOCATION 'abfss://golden@<storage_account>.dfs.core.windows.net/catalog_dev/top_productos';

CREATE TABLE IF NOT EXISTS catalog_dev.golden.actividad_dia_hora (
  dia_semana_num INT, dia_semana STRING, hora_dia INT, franja_horaria STRING,
  total_ordenes BIGINT, total_productos BIGINT, promedio_productos_orden DOUBLE,
  fecha_proceso TIMESTAMP)
USING DELTA
LOCATION 'abfss://golden@<storage_account>.dfs.core.windows.net/catalog_dev/actividad_dia_hora';

CREATE TABLE IF NOT EXISTS catalog_dev.golden.segmentos_clientes (
  user_id INT, total_ordenes BIGINT, total_productos BIGINT, promedio_productos_orden DOUBLE,
  promedio_dias_entre_ordenes DOUBLE, tasa_recompra DOUBLE, departamento_favorito STRING,
  segmento STRING, fecha_proceso TIMESTAMP)
USING DELTA
LOCATION 'abfss://golden@<storage_account>.dfs.core.windows.net/catalog_dev/segmentos_clientes';
