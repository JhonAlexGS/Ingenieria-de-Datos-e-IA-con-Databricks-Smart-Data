-- Consultas usadas en el dashboard (Databricks AI/BI).

-- KPIs generales
SELECT SUM(total_productos_vendidos) AS productos_vendidos,
       ROUND(SUM(tasa_recompra * total_productos_vendidos) * 100
             / SUM(total_productos_vendidos), 1) AS tasa_recompra_pct
FROM catalog_prod.golden.kpi_departamentos;

SELECT SUM(total_ordenes) AS ordenes FROM catalog_prod.golden.actividad_dia_hora;

SELECT COUNT(*) AS clientes FROM catalog_prod.golden.segmentos_clientes;

-- Ventas y recompra por departamento
SELECT departamento, total_productos_vendidos, participacion_pct, tasa_recompra
FROM catalog_prod.golden.kpi_departamentos
ORDER BY total_productos_vendidos DESC;

-- Top 10 productos por departamento
SELECT departamento, ranking, nombre_producto, veces_comprado, tasa_recompra
FROM catalog_prod.golden.top_productos
ORDER BY departamento, ranking;

-- Ordenes por dia y hora
SELECT CONCAT(dia_semana_num, ' - ', dia_semana) AS dia_semana,
       hora_dia, total_ordenes
FROM catalog_prod.golden.actividad_dia_hora
ORDER BY dia_semana_num, hora_dia;

-- Ordenes por franja horaria
SELECT franja_horaria, SUM(total_ordenes) AS ordenes
FROM catalog_prod.golden.actividad_dia_hora
GROUP BY franja_horaria;

-- Segmentos de clientes
SELECT segmento,
       COUNT(*) AS clientes,
       ROUND(AVG(promedio_productos_orden), 2)    AS productos_por_orden,
       ROUND(AVG(promedio_dias_entre_ordenes), 1) AS dias_entre_ordenes,
       ROUND(AVG(tasa_recompra) * 100, 1)         AS tasa_recompra_pct
FROM catalog_prod.golden.segmentos_clientes
GROUP BY segmento
ORDER BY clientes DESC;
