# Proyecto Final - Paso a paso

Apuntes del desarrollo del proyecto, desde la creación de los recursos en Azure hasta el reporte de Power BI. El token de Databricks y el ID de la suscripción se ocultaron.

# Creando el workspace de Databricks

![Captura](img/000.png)

![Captura](img/001.png)

# Creando el Storage Account

Storage Account: `adlsinstacartjg15`

Pasos para crear el Storage Account (Data Lake):

1. En [portal.azure.com](http://portal.azure.com/) se busca "Storage accounts" y se hace clic en + Create.
2. Pestaña Basics:
    - Resource group: el mismo donde se creó el workspace de Databricks.
    - Storage account name: solo minúsculas y números, sin guiones. Se eligió `adlsinstacartjg15`, nombre que se usa en todo el proyecto.
    - Region: la misma del workspace de Databricks.
    - Primary service: Azure Blob Storage or Azure Data Lake Storage Gen2.
    - Performance: Standard. Redundancy: LRS, que es la más barata.
3. Pestaña Advanced: se marca ✅ Enable hierarchical namespace. Esta opción es la que lo convierte en Data Lake Gen2; sin ella, las rutas abfss:// no funcionan y habría que crear el storage de nuevo.
4. Review + create y luego Create. La creación tarda alrededor de un minuto.

![Captura](img/002.png)

![Captura](img/003.png)

![Captura](img/004.png)

## Creando los contenedores

![Captura](img/005.png)

## Cargando el contenido

![Captura](img/006.png)

![Captura](img/007.png)

| Carpeta de destino | Archivo (de la carpeta datasets/) |
| --- | --- |
| instacart/orders | orders.csv |
| instacart/order_products | order_products__prior.csv y order_products__train.csv |
| instacart/products | products.csv |
| instacart/aisles | aisles.csv |
| instacart/departments | departments.csv |

![Captura](img/008.png)

Se usó ese esquema de carpetas por estas razones:

1. **`instacart/` separa los datos por fuente.**
El contenedor raw es la “zona de aterrizaje” de todo el Data Lake. En un proyecto real llegan datos de varios sistemas, cada uno en su carpeta: `raw/instacart/`, `raw/ventas_erp/`, `raw/clientes_crm/`. Así se sabe de dónde vino cada archivo y no se mezclan. En este proyecto hay una sola fuente, pero la estructura queda preparada para agregar otras.
2. **`orders/`, `products/`, etc. separan cada tabla.**
Spark lee la carpeta completa, no un archivo suelto. Con una carpeta por tabla:
    - `order_products/` contiene `prior.csv` y `train.csv`, y Spark los lee juntos como una sola tabla. Así sale `bronze.order_products`.
    - Si llega un archivo nuevo, por ejemplo `orders_2027.csv`, se deja en `orders/` y entra en la siguiente carga sin cambiar el código.
3. **Auto Loader necesita una carpeta que vigilar.**
La ingesta de `order_products` usa Auto Loader. Auto Loader observa un directorio y procesa solo los archivos nuevos que aparecen ahí. Si todos los CSV estuvieran sueltos en la raíz de raw, también leería los de otras tablas.

# Creando el Access Connector (Managed Identity)

![Captura](img/009.png)

![Captura](img/010.png)

![Captura](img/011.png)

![Captura](img/012.png)

## Obteniendo el ID del recurso

![Captura](img/013.png)

![Captura](img/014.png)

![Captura](img/015.png)

![Captura](img/016.png)

![Captura](img/017.png)

```bash
/subscriptions/<subscription_id>/resourceGroups/rg-project-final-jhon-garcia-15-nov/providers/Microsoft.Databricks/accessConnectors/acad-instacart-jhon-garcia-15-nov
```

## Dando permiso al Access Connector sobre el Storage

![Captura](img/018.png)

![Captura](img/019.png)

![Captura](img/020.png)

Se asignó el rol **Storage Blob Data Contributor**. Por qué ese rol y no otro:

| Rol | ¿Sirve? | Motivo |
| --- | --- | --- |
| Storage Blob Data Reader | ❌ | Solo puede leer. El ETL tiene que escribir las tablas Delta en bronze, silver y golden. |
| Storage Blob Data Contributor | ✅ | Puede leer, escribir y borrar archivos. Es justo lo que hace el ETL, incluida la reversión con `dbutils.fs.rm`. |
| Storage Blob Data Owner | ⚠️ | Funciona, pero además puede cambiar permisos (ACLs). Da más acceso del necesario. |
| Contributor (sin “Blob Data”) | ❌ | Es un error común. Administra el recurso (configuración del storage), pero no da acceso a los datos. |

Así se cumple el principio de mínimo privilegio: la Managed Identity recibe solo el permiso que necesita.

### Asignando el miembro (Managed Identity)

![Captura](img/021.png)

![Captura](img/022.png)

![Captura](img/023.png)

![Captura](img/024.png)

![Captura](img/025.png)

# Entorno de Databricks

## Creando el Cluster de Databricks

![Captura](img/026.png)

![Captura](img/027.png)

![Captura](img/028.png)

Se creó un único cluster de propósito general, compartido por ambos ambientes, con prioridad en el bajo costo y la compatibilidad con Unity Catalog:

- Policy: Unrestricted, para poder definir libremente el modo de acceso, el runtime y el tamaño.
- Runtime: 15.4 LTS (Spark 3.5.0), una versión de soporte extendido, estable y compatible con UnityCatalog y Auto Loader. No se usó la versión ML porque el ETL no usa librerías de machine learning.
- Nodo: Standard_D4ds_v4, en modo Single node. El volumen de datos (~1 M de filas por tabla) no justifica workers adicionales.
- Auto-terminación: 20 minutos, para que el cluster no quede encendido sin uso.
- Access mode: Dedicated, asignado al propietario del workspace. Da soporte completo a las UDFs de Python, cache() y Auto Loader. Además, el mismo usuario genera el token de GitHub Actions, así que el  Workflow de producción puede usar este cluster.

¿Por qué sin Photon? Photon venía activado por defecto y se desmarcó deliberadamente:

- Costo: Photon cobra más DBU por hora. Sin él, el cluster quedó en ~0.75 DBU/h.
- Volumen: Photon rinde con cientos de GB o más. Con ~1 M de filas, la mejora de tiempo sería mínima.
- Tipo de carga: el ETL usa una UDF en Python (dia_semana). Photon no ejecuta UDFs de Python, así que esa etapa no se aceleraría.
- Contexto académico: con créditos limitados, se priorizó el costo sobre una mejora de rendimiento poco relevante.

## Creando credencial

La storage credential es la pieza que conecta Databricks con el Data Lake usando la Managed Identity, sin contraseñas ni claves. Es lo que permite cumplir el requisito de que la conexión a la capa raw solo sea con Managed Identity.

La cadena completa:

```
Access Connector  →  Rol IAM en el Storage  →  Storage Credential  →  External Locations
(identidad en       (permiso de leer y        (registro en Unity     (exlt_raw, exlt_bronze,
 Azure)              escribir)                 Catalog)               exlt_silver, ...)
```

1. Access Connector: crea una identidad en Azure, similar a un "usuario robot".
2. Rol IAM: le da a esa identidad permiso sobre `adlsinstacartjg15`.
3. Storage Credential (`cred_instacart_jhon_garcia_15_nov`): le indica a Unity Catalog que, cuando necesite entrar al storage, se identifique con esa identidad.
4. External Locations: combinan la credencial con una ruta concreta. Por ejemplo, `exlt_raw` equivale a usar la credencial para `abfss://raw@adlsinstacartjg15.dfs.core.windows.net/`.

![Captura](img/029.png)

![Captura](img/030.png)

![Captura](img/031.png)

![Captura](img/032.png)

### Estructura de carpetas

![Captura](img/033.png)

![Captura](img/034.png)

Esta estructura inicial se reemplazó después por el Git folder conectado al repositorio (ver *Conectando con Git*).

```bash
Workspace
  └── Users / oct_jhonv2@hotmail.com
      └── instacart_dev/                 ← carpeta del proyecto (ambiente dev)
          ├── PrepAmb/
          │   └── PrepAmb                ← notebook SQL de preparación de ambiente
          ├── proceso/
          │   ├── 00_utils
          │   ├── 01_prep_ambiente
          │   ├── 02_ingest_...
          │   └── ...
          └── reversion/
              └── drop_medallion
```

![Captura](img/035.png)

### Creando los notebooks

![Captura](img/036.png)

# Conectando con Git

![Captura](img/037.png)

![Captura](img/038.png)

![Captura](img/039.png)

![Captura](img/040.png)

![Captura](img/041.png)

![Captura](img/042.png)

![Captura](img/043.png)

![Captura](img/044.png)

![Captura](img/045.png)

![Captura](img/046.png)

![Captura](img/047.png)

![Captura](img/048.png)

![Captura](img/049.png)

![Captura](img/050.png)

![Captura](img/051.png)

![Captura](img/052.png)

![Captura](img/053.png)

![Captura](img/054.png)

![Captura](img/055.png)

![Captura](img/056.png)

![Captura](img/057.png)

![Captura](img/058.png)

![Captura](img/059.png)

![Captura](img/060.png)

La primera ejecución de cada notebook falla con este error, lo cual es esperado:

```
ValueError: Los parametros 'catalogo' y 'storage_name' son obligatorios
```

Ocurre porque los widgets (los campos de parámetros) se crean en esa primera ejecución y todavía están vacíos. Después de llenar `storage_name` con `adlsinstacartjg15`, el notebook se ejecuta correctamente.

![Captura](img/061.png)

Se ejecutan los notebooks en orden hasta `04_load`.

# Creación de grupos

![Captura](img/062.png)

![Captura](img/063.png)

![Captura](img/064.png)

![Captura](img/065.png)

![Captura](img/066.png)

![Captura](img/067.png)

![Captura](img/068.png)

### Agregando un miembro al grupo

![Captura](img/069.png)

![Captura](img/070.png)

![Captura](img/071.png)

![Captura](img/072.png)

Se continúa con `05_grants`.

![Captura](img/073.png)

# Token de Databricks

![Captura](img/074.png)

![Captura](img/075.png)

![Captura](img/076.png)

![Captura](img/077.png)

![Captura](img/078.png)

dapi******** (oculto)

## Obteniendo el ID del cluster

### Opción 1: Mediante la URL

![Captura](img/079.png)

![Captura](img/080.png)

Se obtiene el identificador del cluster

```bash
https://adb-7405613546610641.1.azuredatabricks.net/compute/clusters
/1114-064306-fv2yfjxe?o=7405613546610641
```

### Opción 2: Mediante el JSON del cluster

![Captura](img/081.png)

![Captura](img/082.png)

![Captura](img/083.png)

## URL del workspace

Se entra al cluster y se toma la URL del navegador hasta `.net`:

![Captura](img/084.png)

```bash
https://adb-7405613546610641.1.azuredatabricks.net
```

# Creando los secrets en GitHub

![Captura](img/085.png)

![Captura](img/086.png)

![Captura](img/087.png)

| Name | Secret |
| --- | --- |
| `DATABRICKS_HOST` | URL del workspace de Databricks |
| `DATABRICKS_TOKEN` | Token de acceso personal (`dapi...`) |
| `DATABRICKS_CLUSTER_ID` | ID del cluster previamente creado |
| `STORAGE_ACCOUNT_NAME` | Nombre del Storage Account (`adlsinstacartjg15`) |

![Captura](img/088.png)

Valores utilizados en el proyecto:

```bash
Storage Account:
adlsinstacartjg15

Access Connector:
acad-instacart-jhon-garcia-15-nov

Id:
/subscriptions/<subscription_id>/resourceGroups/rg-project-final-jhon-garcia-15-nov/providers/Microsoft.Databricks/accessConnectors/acad-instacart-jhon-garcia-15-nov

Nombre de la credencial:
cred_instacart_jhon_garcia_15_nov

Id del cluster:
1114-064306-fv2yfjxe

Token:
dapi******** (oculto)

URL del WorkSpace:
https://adb-7405613546610641.1.azuredatabricks.net
```

# Realizando el pull request

![Captura](img/089.png)

![Captura](img/090.png)

![Captura](img/091.png)

![Captura](img/092.png)

![Captura](img/093.png)

# Ejecutando en Databricks

![Captura](img/094.png)

**1. Qué dispara el pipeline**

Al inicio de `.github/workflows/deploy-prod.yml` se encuentra esto:

```yaml
on:
  push:
    branches: [main]
    paths:
      - "proceso/**"
      - ".github/workflows/deploy-prod.yml"
  workflow_dispatch:
```

GitHub revisa cada push. Si llega un push a `main` que cambia algo en `proceso/` o en el propio YAML, ejecuta el workflow automáticamente. El merge del pull request cuenta como push a `main`, y por eso arrancó. `workflow_dispatch` agrega además un botón **Run workflow** en Actions para lanzarlo a mano.

**2. Para qué sirven los secrets: solo para autenticarse**

Los secrets no disparan nada. GitHub los usa como “llave” para conectarse a Databricks y darle órdenes por la API:

| Secret | Uso |
| --- | --- |
| `DATABRICKS_HOST` | A qué workspace se llama |
| `DATABRICKS_TOKEN` | Con qué permiso (actúa como el usuario que lo generó) |
| `DATABRICKS_CLUSTER_ID` | En qué cluster se corren las tareas |
| `STORAGE_ACCOUNT_NAME` | Parámetro que se pasa a los notebooks |

**3. Por qué se enciende el cluster**

![Captura](img/095.png)

En el último paso, GitHub llama a la API `jobs/run-now` de Databricks. Cada tarea del job tiene configurado:

```json
"existing_cluster_id": "<cluster id>"
```

Cuando un job tiene que correr en un cluster que está apagado, Databricks lo enciende automáticamente. Al terminar, el cluster se apaga solo a los 20 minutos de inactividad, por la auto-terminación configurada.

**La cadena completa**

```
merge a main  →  GitHub detecta el push (on: push main)
              →  ejecuta el YAML usando los secrets para autenticarse
              →  llama a Databricks: importa notebooks, crea el job, run-now
              →  Databricks enciende el cluster y corre las tareas
```

Al abrir la ejecución, se ven los dos jobs (Desplegar y Ejecutar). Dentro de Ejecutar aparece el estado de cada tarea, actualizado cada 30 segundos.

![Captura](img/096.png)

![Captura](img/097.png)

# Revisión del Job & Pipeline de Databricks

![Captura](img/098.png)

![Captura](img/099.png)

![Captura](img/100.png)

![Captura](img/101.png)

# Creación del Dashboard

![Captura](img/102.png)

![Captura](img/103.png)

Las consultas SQL del dashboard se tomaron del archivo `dashboard/queries_dashboard.sql` (luego convertido a `dashboard/queries_dashboard.ipynb`), que reúne en un solo lugar todas las consultas usadas para construir las visualizaciones.

![Captura](img/104.png)

![Captura](img/105.png)

![Captura](img/106.png)

![Captura](img/107.png)

![Captura](img/108.png)

![Captura](img/109.png)

# Publicando el dashboard

![Captura](img/110.png)

![Captura](img/111.png)

![Captura](img/112.png)

```bash
https://adb-7405613546610641.1.azuredatabricks.net/dashboardsv3/01f1e09fab6b18e0a53261b53036e8df/published?o=7405613546610641

```

![Captura](img/113.png)

# Activar External Delta Sharing

![Captura](img/114.png)

El metastore tiene External OpenSharing deshabilitado y solo se puede activar desde la consola de la cuenta de Databricks, a la que no se pudo ingresar con una cuenta personal de Microsoft. Por eso se dejó creado el share con las tablas de golden, sin el recipient externo.

# Conexión con Power BI

![Captura](img/115.png)

![Captura](img/116.png)

![Captura](img/117.png)

![Captura](img/118.png)

En el campo “Clave de cuenta” se ingresa el token de Databricks.

![Captura](img/119.png)

![Captura](img/120.png)

![Captura](img/121.png)