/*
===============================================================================
PROYECTO INTEGRADOR TURISMOUQ - ENTREGA 2
Archivo: 03_tablespace_historico_y_vista.sql
IMPORTANTE: este archivo tiene dos secciones y dos usuarios de ejecución.
A) SYSTEM en FREEPDB1: ejecutar solo si TS_HISTORICO aún no existe.
B) TURISMO_TEST en FREEPDB1: ejecutar la sección de histórico y vista.
Entorno trabajado: Oracle Free en Docker; datafile dentro del contenedor.
===============================================================================

JUSTIFICACIÓN:
Se separa el histórico de reservas para organizar los datos de periodos
cerrados en un tablespace propio, facilitar su administración y permitir
estrategias independientes de almacenamiento/backup. El archivado aquí es
una copia no destructiva: no borra registros de RESERVA.
*/

-- ==================== SECCIÓN A: CONEXIÓN SYSTEM ===========================
-- Ejecutar una sola vez y solo si TS_HISTORICO no existe.
-- En SQL Developer, seleccionar la conexión SYSTEM_FREEPDB1.
--
-- CREATE TABLESPACE TS_HISTORICO
-- DATAFILE '/opt/oracle/oradata/FREE/FREEPDB1/ts_historico01.dbf'
-- SIZE 20M AUTOEXTEND ON NEXT 10M MAXSIZE UNLIMITED;
--
-- ALTER USER TURISMO_TEST QUOTA 20M ON TS_HISTORICO;
-- GRANT CREATE MATERIALIZED VIEW TO TURISMO_TEST;
--
-- Si el tablespace ya existe, NO ejecutar CREATE TABLESPACE otra vez.
-- Verificar con:
-- SELECT TABLESPACE_NAME, STATUS FROM DBA_TABLESPACES
-- WHERE TABLESPACE_NAME = 'TS_HISTORICO';

-- ================== SECCIÓN B: CONEXIÓN TURISMO_TEST =======================

-- 1. Crear la tabla histórica en el tablespace.
-- En el entorno actual RESERVA_HISTORICA ya existe: omitir este CREATE TABLE.
-- No borrar la tabla para volver a ejecutar el script.
CREATE TABLE RESERVA_HISTORICA (
    ID_RESERVA      NUMBER(10) NOT NULL,
    ID_CLIENTE      NUMBER(10) NOT NULL,
    FECHA_CHECKIN   DATE NOT NULL,
    FECHA_CHECKOUT  DATE NOT NULL,
    ESTADO          VARCHAR2(20) NOT NULL,
    FECHA_ARCHIVO   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_RESERVA_HISTORICA PRIMARY KEY (ID_RESERVA)
) TABLESPACE TS_HISTORICO;

-- 2. Archivar una copia de reservas cerradas antes de 2025.
-- NOT EXISTS evita duplicar ID_RESERVA. Ejecutar en una sesión limpia:
-- el COMMIT confirma todos los cambios pendientes de esa sesión.
INSERT INTO RESERVA_HISTORICA (
    ID_RESERVA, ID_CLIENTE, FECHA_CHECKIN, FECHA_CHECKOUT, ESTADO, FECHA_ARCHIVO
)
SELECT R.ID_RESERVA, R.ID_CLIENTE, R.FECHA_CHECKIN, R.FECHA_CHECKOUT,
       R.ESTADO, SYSDATE
FROM RESERVA R
WHERE R.FECHA_CHECKOUT < DATE '2025-01-01'
  AND R.ESTADO IN ('Completada', 'Cancelada')
  AND NOT EXISTS (
      SELECT 1
      FROM RESERVA_HISTORICA H
      WHERE H.ID_RESERVA = R.ID_RESERVA
  );
COMMIT;

-- 3. Vista materializada de ocupación mensual.
-- Esta definición corregida genera todos los meses entre la primera entrada
-- y el último día/noche ocupado, incluidos meses sin check-in propio.
-- En el entorno actual MV_OCUPACION_MENSUAL ya existe. NO ejecutar este CREATE
-- directamente: para sustituir la vista, guardar primero evidencia/definición,
-- coordinar la recreación y ejecutar DROP MATERIALIZED VIEW conscientemente.
-- REFRESH COMPLETE ON DEMAND: refresco manual o programado.
CREATE MATERIALIZED VIEW MV_OCUPACION_MENSUAL
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
WITH RANGO AS (
    SELECT TRUNC(MIN(FECHA_CHECKIN), 'MM') AS MIN_MES,
           TRUNC(MAX(FECHA_CHECKOUT - 1), 'MM') AS MAX_MES
    FROM RESERVA_HABITACION
),
MESES AS (
    SELECT ADD_MONTHS(MIN_MES, LEVEL - 1) AS MES
    FROM RANGO
    CONNECT BY LEVEL <= MONTHS_BETWEEN(MAX_MES, MIN_MES) + 1
)
SELECT
    H.ID_ALOJAMIENTO,
    A.NOMBRE AS ALOJAMIENTO,
    M.MES,
    EXTRACT(YEAR FROM M.MES) AS ANIO,
    EXTRACT(MONTH FROM M.MES) AS NUM_MES,
    COUNT(DISTINCT R.ID_RESERVA) AS TOTAL_RESERVAS,
    COUNT(DISTINCT RH.ID_RESERVA_HABITACION) AS HABITACIONES_RESERVADAS,
    SUM(
        LEAST(RH.FECHA_CHECKOUT, ADD_MONTHS(M.MES, 1))
        - GREATEST(RH.FECHA_CHECKIN, M.MES)
    ) AS NOCHES_OCUPADAS
FROM MESES M
JOIN RESERVA_HABITACION RH
  ON RH.FECHA_CHECKIN < ADD_MONTHS(M.MES, 1)
 AND RH.FECHA_CHECKOUT > M.MES
JOIN RESERVA R ON R.ID_RESERVA = RH.ID_RESERVA
JOIN HABITACION H ON H.ID_HABITACION = RH.ID_HABITACION
JOIN ALOJAMIENTO A ON A.ID_ALOJAMIENTO = H.ID_ALOJAMIENTO
WHERE R.ESTADO <> 'Cancelada'
GROUP BY H.ID_ALOJAMIENTO, A.NOMBRE, M.MES;

-- 4. Verificar ubicación y estado de los objetos.
SELECT TABLE_NAME, TABLESPACE_NAME
FROM USER_TABLES
WHERE TABLE_NAME = 'RESERVA_HISTORICA';

SELECT MVIEW_NAME, REFRESH_MODE, REFRESH_METHOD, STALENESS
FROM USER_MVIEWS
WHERE MVIEW_NAME = 'MV_OCUPACION_MENSUAL';

-- Para actualizar posteriormente:
-- BEGIN DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C'); END;
-- /

//### Política de actualización de la vista materializada''MV_OCUPACION_MENSUAL'' (no supe como mas hacerlo profe:(  )

//La vista materializada utiliza una política de actualización bajo demanda (`ON DEMAND`) y un método de actualización completa (`COMPLETE`). Esta configuración permite controlar cuándo se recalculan los indicadores mensuales de ocupación y evita ejecutar una actualización completa cada vez que se modifica una tabla base.

//Se seleccionó el método completo porque permite recalcular los resultados a partir de los datos actuales de las tablas relacionadas, manteniendo la consistencia de los indicadores de reservas, habitaciones reservadas y noches ocupadas. La actualización puede programarse o ejecutarse después de procesos importantes de registro o modificación de reservas, según las necesidades operativas del sistema.

//La verificación en el diccionario de datos de Oracle muestra que la vista está en estado `FRESH` y que su última actualización fue de tipo `COMPLETE`.