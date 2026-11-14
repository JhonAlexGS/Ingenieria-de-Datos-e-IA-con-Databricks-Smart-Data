-- Permisos sobre catalog_prod.
-- ingenieros_datos: lectura y escritura en las tres capas
-- analistas: solo lectura en golden

-- Ingenieros de datos
GRANT USE CATALOG ON CATALOG catalog_prod TO `ingenieros_datos`;
GRANT USE SCHEMA, SELECT, MODIFY ON SCHEMA catalog_prod.bronze TO `ingenieros_datos`;
GRANT USE SCHEMA, SELECT, MODIFY ON SCHEMA catalog_prod.silver TO `ingenieros_datos`;
GRANT USE SCHEMA, SELECT, MODIFY ON SCHEMA catalog_prod.golden TO `ingenieros_datos`;

-- Analistas (solo golden)
GRANT USE CATALOG ON CATALOG catalog_prod TO `analistas`;
GRANT USE SCHEMA, SELECT ON SCHEMA catalog_prod.golden TO `analistas`;

-- External locations
-- Lectura de archivos de la capa raw
GRANT READ FILES ON EXTERNAL LOCATION `exlt_raw` TO `ingenieros_datos`;

-- Validacion
SHOW GRANTS ON CATALOG catalog_prod;
SHOW GRANTS ON SCHEMA catalog_prod.golden;
SHOW GRANTS ON EXTERNAL LOCATION `exlt_raw`;

-- Revocar (ejemplo)
-- REVOKE SELECT ON SCHEMA catalog_prod.golden FROM `analistas`;
