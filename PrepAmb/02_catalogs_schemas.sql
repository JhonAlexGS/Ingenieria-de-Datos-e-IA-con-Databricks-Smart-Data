-- Catalogos de desarrollo y produccion con sus schemas.
-- Se reemplaza <storage_account> por el nombre del storage.

-- desarrollo
CREATE CATALOG IF NOT EXISTS catalog_dev
  MANAGED LOCATION 'abfss://catalog@<storage_account>.dfs.core.windows.net/catalog_dev'
  COMMENT 'Ambiente de desarrollo - ETL Instacart';

CREATE SCHEMA IF NOT EXISTS catalog_dev.bronze COMMENT 'Datos crudos tipados + auditoría';
CREATE SCHEMA IF NOT EXISTS catalog_dev.silver COMMENT 'Datos limpios, enriquecidos e integrados';
CREATE SCHEMA IF NOT EXISTS catalog_dev.golden COMMENT 'Agregados de negocio para el dashboard';

-- produccion
CREATE CATALOG IF NOT EXISTS catalog_prod
  MANAGED LOCATION 'abfss://catalog@<storage_account>.dfs.core.windows.net/catalog_prod'
  COMMENT 'Ambiente de producción - ETL Instacart';

CREATE SCHEMA IF NOT EXISTS catalog_prod.bronze COMMENT 'Datos crudos tipados + auditoría';
CREATE SCHEMA IF NOT EXISTS catalog_prod.silver COMMENT 'Datos limpios, enriquecidos e integrados';
CREATE SCHEMA IF NOT EXISTS catalog_prod.golden COMMENT 'Agregados de negocio para el dashboard';

SHOW SCHEMAS IN catalog_dev;
SHOW SCHEMAS IN catalog_prod;
