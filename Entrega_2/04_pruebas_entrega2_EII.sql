/*
===============================================================================
PROYECTO INTEGRADOR TURISMOUQ - ENTREGA 2
Archivo: 04_pruebas_entrega2.sql
Ejecutar conectado como TURISMO_TEST después de los scripts 01, 02 y 03.
Las consultas de lectura no alteran datos. La prueba de auditoría modifica y
restaura una tarifa y hace COMMIT para conservar los registros de auditoría.
EJECUTAR ESA PRUEBA EN UNA SESIÓN/HOJA LIMPIA, sin cambios pendientes ajenos.
===============================================================================
*/

-- 1. Verificar estado del paquete y sus objetos.
SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_NAME = 'PKG_TURISMO'
ORDER BY OBJECT_TYPE;

-- 2. Prueba de cálculo que cruza temporadas (valor esperado en el entorno
-- probado: 513500 para habitación 1 del 30-mar-2024 al 02-abr-2024).
SELECT PKG_TURISMO.FN_VALOR_ESTADIA(
           1, DATE '2024-03-30', DATE '2024-04-02'
       ) AS VALOR_ESTADIA
FROM DUAL;

-- 3. Prueba del cursor explícito parametrizado de liquidación mensual.
DECLARE
    V_FILA PKG_TURISMO.CUR_LIQUIDACION_MENSUAL%ROWTYPE;
BEGIN
    OPEN PKG_TURISMO.CUR_LIQUIDACION_MENSUAL(1, 2026, 11);
    FETCH PKG_TURISMO.CUR_LIQUIDACION_MENSUAL INTO V_FILA;

    IF PKG_TURISMO.CUR_LIQUIDACION_MENSUAL%FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Alojamiento: ' || V_FILA.ALOJAMIENTO);
        DBMS_OUTPUT.PUT_LINE('Reservas: ' || V_FILA.TOTAL_RESERVAS);
        DBMS_OUTPUT.PUT_LINE('Recaudado: ' || V_FILA.TOTAL_RECAUDADO);
    END IF;

    CLOSE PKG_TURISMO.CUR_LIQUIDACION_MENSUAL;
END;
/

-- 4. Auditoría de tarifas: elegir una tarifa y guardar su valor original.
-- La actualización se restaura y el trigger registra ambos cambios.
-- IMPORTANTE: COMMIT confirma toda la transacción de esta sesión; ejecutar
-- solo en una sesión limpia, sin cambios pendientes que se quieran conservar
-- sin confirmar. No usar ROLLBACK aquí si se necesita conservar la evidencia.
DECLARE
    V_ID TARIFA.ID_TARIFA%TYPE;
    V_VALOR TARIFA.VALOR_NOCHE%TYPE;
BEGIN
    SELECT ID_TARIFA, VALOR_NOCHE
    INTO V_ID, V_VALOR
    FROM TARIFA
    WHERE ID_HABITACION = 1
      AND ROWNUM = 1;

    UPDATE TARIFA
    SET VALOR_NOCHE = V_VALOR + 1
    WHERE ID_TARIFA = V_ID;

    UPDATE TARIFA
    SET VALOR_NOCHE = V_VALOR
    WHERE ID_TARIFA = V_ID;

    COMMIT;
END;
/

SELECT ID_TARIFA, OPERACION, VALOR_ANTERIOR, VALOR_NUEVO,
       USUARIO_BD, FECHA_CAMBIO
FROM AUDITORIA_TARIFA
WHERE ID_HABITACION = 1
ORDER BY ID_AUDITORIA DESC
FETCH FIRST 10 ROWS ONLY;

-- 5. Verificación del trigger antisolape (sin insertar una reserva conflictiva).
SELECT TRIGGER_NAME, STATUS, TRIGGERING_EVENT
FROM USER_TRIGGERS
WHERE TRIGGER_NAME IN ('TRG_AUDITORIA_TARIFA', 'TRG_EVITAR_SOLAPAMIENTO')
ORDER BY TRIGGER_NAME;

-- La prueba real de conflicto ya ejecutada devolvió ORA-20016. Para repetirla
-- de forma segura, se recomienda usar dos fechas/una habitación de prueba y
-- hacer rollback de la transacción; no copiar IDs de reservas sin verificarlos.

-- 6. Verificar histórico y tablespace.
SELECT COUNT(*) AS RESERVAS_ARCHIVADAS,
       MIN(FECHA_CHECKOUT) AS CHECKOUT_MAS_ANTIGUO,
       MAX(FECHA_CHECKOUT) AS CHECKOUT_MAS_RECIENTE
FROM RESERVA_HISTORICA;

SELECT TABLE_NAME, TABLESPACE_NAME
FROM USER_TABLES
WHERE TABLE_NAME = 'RESERVA_HISTORICA';

-- 7. Consultar la ocupación mensual calculada.
SELECT ID_ALOJAMIENTO, ALOJAMIENTO, MES, TOTAL_RESERVAS,
       HABITACIONES_RESERVADAS, NOCHES_OCUPADAS
FROM MV_OCUPACION_MENSUAL
WHERE ID_ALOJAMIENTO = 1
ORDER BY MES;

-- 8. Verificar la política y frescura de la vista materializada.
SELECT MVIEW_NAME, REFRESH_MODE, REFRESH_METHOD, STALENESS
FROM USER_MVIEWS
WHERE MVIEW_NAME = 'MV_OCUPACION_MENSUAL';

-- Refresco manual opcional; actualiza el contenido de la vista materializada:
-- BEGIN DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C'); END;
-- /
