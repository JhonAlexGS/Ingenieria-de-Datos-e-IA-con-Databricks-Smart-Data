-- Se comparte la capa golden con un usuario externo mediante Delta Sharing.

CREATE SHARE IF NOT EXISTS share_instacart_golden
  COMMENT 'KPIs de negocio Instacart (capa golden)';

ALTER SHARE share_instacart_golden ADD TABLE catalog_prod.golden.kpi_departamentos WITH HISTORY;
ALTER SHARE share_instacart_golden ADD TABLE catalog_prod.golden.top_productos;
ALTER SHARE share_instacart_golden ADD TABLE catalog_prod.golden.actividad_dia_hora;

CREATE RECIPIENT IF NOT EXISTS recipient_area_comercial
  COMMENT 'Área comercial - consumo externo de KPIs';

GRANT SELECT ON SHARE share_instacart_golden TO RECIPIENT recipient_area_comercial;

-- Validacion
SHOW ALL IN SHARE share_instacart_golden;
DESCRIBE RECIPIENT recipient_area_comercial;
