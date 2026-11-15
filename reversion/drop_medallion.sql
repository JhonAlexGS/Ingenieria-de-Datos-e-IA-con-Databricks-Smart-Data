-- Eliminacion de tablas, schemas y catalogo (ejemplo con catalog_prod).
-- Las carpetas del Data Lake se eliminan con reversion/drop_medallion.ipynb

-- golden
DROP TABLE IF EXISTS catalog_prod.golden.kpi_departamentos;
DROP TABLE IF EXISTS catalog_prod.golden.top_productos;
DROP TABLE IF EXISTS catalog_prod.golden.actividad_dia_hora;
DROP TABLE IF EXISTS catalog_prod.golden.segmentos_clientes;

-- silver
DROP TABLE IF EXISTS catalog_prod.silver.productos;
DROP TABLE IF EXISTS catalog_prod.silver.ordenes;
DROP TABLE IF EXISTS catalog_prod.silver.detalle_ordenes;

-- bronze
DROP TABLE IF EXISTS catalog_prod.bronze.orders;
DROP TABLE IF EXISTS catalog_prod.bronze.order_products;
DROP TABLE IF EXISTS catalog_prod.bronze.products;
DROP TABLE IF EXISTS catalog_prod.bronze.aisles;
DROP TABLE IF EXISTS catalog_prod.bronze.departments;

-- schemas
DROP SCHEMA IF EXISTS catalog_prod.golden CASCADE;
DROP SCHEMA IF EXISTS catalog_prod.silver CASCADE;
DROP SCHEMA IF EXISTS catalog_prod.bronze CASCADE;

-- catalogo
DROP CATALOG IF EXISTS catalog_prod CASCADE;

-- delta sharing
DROP SHARE IF EXISTS share_instacart_golden;
DROP RECIPIENT IF EXISTS recipient_area_comercial;

-- external locations (solo si se elimina todo el proyecto)
-- DROP EXTERNAL LOCATION IF EXISTS `exlt_raw`;
-- DROP EXTERNAL LOCATION IF EXISTS `exlt_bronze`;
-- DROP EXTERNAL LOCATION IF EXISTS `exlt_silver`;
-- DROP EXTERNAL LOCATION IF EXISTS `exlt_golden`;
-- DROP EXTERNAL LOCATION IF EXISTS `exlt_catalog`;
