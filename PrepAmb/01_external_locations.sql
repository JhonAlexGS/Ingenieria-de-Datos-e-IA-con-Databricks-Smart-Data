-- External locations sobre cada contenedor del storage.
-- Usan la storage credential creada con el Access Connector (Managed Identity).
-- Antes de ejecutar se reemplaza <storage_account> por el nombre del storage.

CREATE EXTERNAL LOCATION IF NOT EXISTS `exlt_raw`
  URL 'abfss://raw@<storage_account>.dfs.core.windows.net/'
  WITH (STORAGE CREDENTIAL `cred_instacart_jhon_garcia_15_nov`)
  COMMENT 'Capa RAW: archivos fuente CSV de Instacart';

CREATE EXTERNAL LOCATION IF NOT EXISTS `exlt_bronze`
  URL 'abfss://bronze@<storage_account>.dfs.core.windows.net/'
  WITH (STORAGE CREDENTIAL `cred_instacart_jhon_garcia_15_nov`)
  COMMENT 'Capa BRONZE: tablas Delta crudas tipadas';

CREATE EXTERNAL LOCATION IF NOT EXISTS `exlt_silver`
  URL 'abfss://silver@<storage_account>.dfs.core.windows.net/'
  WITH (STORAGE CREDENTIAL `cred_instacart_jhon_garcia_15_nov`)
  COMMENT 'Capa SILVER: tablas Delta limpias e integradas';

CREATE EXTERNAL LOCATION IF NOT EXISTS `exlt_golden`
  URL 'abfss://golden@<storage_account>.dfs.core.windows.net/'
  WITH (STORAGE CREDENTIAL `cred_instacart_jhon_garcia_15_nov`)
  COMMENT 'Capa GOLDEN: agregados de negocio';

CREATE EXTERNAL LOCATION IF NOT EXISTS `exlt_catalog`
  URL 'abfss://catalog@<storage_account>.dfs.core.windows.net/'
  WITH (STORAGE CREDENTIAL `cred_instacart_jhon_garcia_15_nov`)
  COMMENT 'Managed location de los catálogos dev y prod';

-- Validacion
SHOW EXTERNAL LOCATIONS;
