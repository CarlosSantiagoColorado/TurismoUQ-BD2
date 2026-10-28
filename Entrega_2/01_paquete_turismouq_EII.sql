    /*
    ===============================================================================
    PROYECTO INTEGRADOR TURISMOUQ - BASES DE DATOS II - ENTREGA 2
    Nombres: Carlos Santiago Colorado - John Angel Cardona
    Archivo: 01_paquete_turismouq.sql
    Ejecutar conectado como TURISMO_TEST en FREEPDB1.
    Dependencias: CLIENTE, HABITACION, TEMPORADA, TARIFA, RESERVA,
                  RESERVA_HABITACION, ALOJAMIENTO, PAGO.
    ===============================================================================
    */
    
    -- 1. Especificación del paquete: función, procedimiento y cursor parametrizado.
    -- NOTA DE NEGOCIO: el cursor asigna el pago completo a cada alojamiento que
    -- tenga al menos una habitación en esa reserva. EXISTS evita duplicarlo por
    -- varias habitaciones del mismo alojamiento. Si una reserva puede incluir
    -- alojamientos distintos, se debe definir una regla de reparto del pago.
    CREATE OR REPLACE PACKAGE PKG_TURISMO AS
        FUNCTION FN_VALOR_ESTADIA(
            P_ID_HABITACION IN NUMBER,
            P_FECHA_IN      IN DATE,
            P_FECHA_OUT     IN DATE
        ) RETURN NUMBER;
    
        PROCEDURE SP_CREAR_RESERVA(
            P_ID_CLIENTE    IN NUMBER,
            P_ID_HABITACION IN NUMBER,
            P_FECHA_IN      IN DATE,
            P_FECHA_OUT     IN DATE,
            P_HUESPEDES      IN NUMBER,
            P_ID_RESERVA    OUT NUMBER
        );
    
        TYPE T_LIQUIDACION IS RECORD (
            ID_ALOJAMIENTO  NUMBER,
            ALOJAMIENTO     VARCHAR2(200),
            TOTAL_RESERVAS  NUMBER,
            TOTAL_RECAUDADO NUMBER
        );
    
        CURSOR CUR_LIQUIDACION_MENSUAL(
            P_ID_ALOJAMIENTO IN NUMBER,
            P_ANIO           IN NUMBER,
            P_MES            IN NUMBER
        ) RETURN T_LIQUIDACION;
    END PKG_TURISMO;
    /
    
    -- 2. Cuerpo del paquete.
    CREATE OR REPLACE PACKAGE BODY PKG_TURISMO AS
    
        CURSOR CUR_LIQUIDACION_MENSUAL(
            P_ID_ALOJAMIENTO IN NUMBER,
            P_ANIO           IN NUMBER,
            P_MES            IN NUMBER
        ) RETURN T_LIQUIDACION IS
            WITH PARAMETROS AS (
                SELECT TO_DATE(P_ANIO || LPAD(P_MES, 2, '0') || '01',
                               'YYYYMMDD') AS INICIO_MES
                FROM DUAL
            ),
            RESERVAS_MES AS (
                SELECT COUNT(DISTINCT R.ID_RESERVA) AS TOTAL_RESERVAS
                FROM RESERVA R
                JOIN RESERVA_HABITACION RH ON RH.ID_RESERVA = R.ID_RESERVA
                JOIN HABITACION H ON H.ID_HABITACION = RH.ID_HABITACION
                CROSS JOIN PARAMETROS P
                WHERE H.ID_ALOJAMIENTO = P_ID_ALOJAMIENTO
                  AND R.ESTADO <> 'Cancelada'
                  AND RH.FECHA_CHECKIN < ADD_MONTHS(P.INICIO_MES, 1)
                  AND RH.FECHA_CHECKOUT > P.INICIO_MES
            ),
                    PAGOS_MES AS (
                SELECT NVL(SUM(PA.MONTO), 0) AS TOTAL_RECAUDADO
                FROM PAGO PA
                CROSS JOIN PARAMETROS P
                WHERE PA.ESTADO = 'Exitoso'
                  AND PA.FECHA_PAGO >= P.INICIO_MES
                  AND PA.FECHA_PAGO < ADD_MONTHS(P.INICIO_MES, 1)
                  AND EXISTS (
                      SELECT 1
                      FROM RESERVA_HABITACION RH
                      JOIN HABITACION H
                        ON H.ID_HABITACION = RH.ID_HABITACION
                      WHERE RH.ID_RESERVA = PA.ID_RESERVA
                        AND H.ID_ALOJAMIENTO = P_ID_ALOJAMIENTO
                  )
            )
            SELECT A.ID_ALOJAMIENTO,
                   A.NOMBRE AS ALOJAMIENTO,
                   RM.TOTAL_RESERVAS,
                   PM.TOTAL_RECAUDADO
            FROM ALOJAMIENTO A
            CROSS JOIN RESERVAS_MES RM
            CROSS JOIN PAGOS_MES PM
            WHERE A.ID_ALOJAMIENTO = P_ID_ALOJAMIENTO;
    
        FUNCTION FN_VALOR_ESTADIA(
            P_ID_HABITACION IN NUMBER,
            P_FECHA_IN      IN DATE,
            P_FECHA_OUT     IN DATE
        ) RETURN NUMBER
        IS
            V_FECHA      DATE;
            V_VALOR_NOCHE TARIFA.VALOR_NOCHE%TYPE;
            V_TOTAL      NUMBER := 0;
        BEGIN
            IF P_ID_HABITACION IS NULL OR P_FECHA_IN IS NULL
               OR P_FECHA_OUT IS NULL OR TRUNC(P_FECHA_OUT) <= TRUNC(P_FECHA_IN) THEN
                RAISE_APPLICATION_ERROR(-20010,
                    'Las fechas son invalidas: checkout debe ser posterior al checkin.');
            END IF;
    
            FOR D IN 0 .. TRUNC(P_FECHA_OUT) - TRUNC(P_FECHA_IN) - 1 LOOP
                V_FECHA := TRUNC(P_FECHA_IN) + D;
    
                BEGIN
                    SELECT T.VALOR_NOCHE
                    INTO V_VALOR_NOCHE
                    FROM TARIFA T
                    JOIN TEMPORADA TE ON TE.ID_TEMPORADA = T.ID_TEMPORADA
                    WHERE T.ID_HABITACION = P_ID_HABITACION
                      AND V_FECHA BETWEEN TRUNC(TE.FECHA_INICIO)
                                      AND TRUNC(TE.FECHA_FIN);
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        RAISE_APPLICATION_ERROR(-20017,
                            'No existe tarifa para la habitacion y fecha ' ||
                            TO_CHAR(V_FECHA, 'YYYY-MM-DD'));
                    WHEN TOO_MANY_ROWS THEN
                        RAISE_APPLICATION_ERROR(-20018,
                            'Hay temporadas superpuestas para la fecha ' ||
                            TO_CHAR(V_FECHA, 'YYYY-MM-DD'));
                END;
    
                V_TOTAL := V_TOTAL + V_VALOR_NOCHE;
            END LOOP;
    
            RETURN V_TOTAL;
        END FN_VALOR_ESTADIA;
    
    
        PROCEDURE SP_CREAR_RESERVA(
            P_ID_CLIENTE    IN NUMBER,
            P_ID_HABITACION IN NUMBER,
            P_FECHA_IN      IN DATE,
            P_FECHA_OUT     IN DATE,
            P_HUESPEDES      IN NUMBER,
            P_ID_RESERVA    OUT NUMBER
        )
        IS
            V_CAPACIDAD HABITACION.CAPACIDAD%TYPE;
            V_CLIENTE  NUMBER;
            V_OCUPADA  NUMBER;
        BEGIN
            IF P_FECHA_IN IS NULL OR P_FECHA_OUT IS NULL
               OR TRUNC(P_FECHA_OUT) <= TRUNC(P_FECHA_IN) THEN
                RAISE_APPLICATION_ERROR(-20010,
                    'Checkout debe ser posterior al checkin.');
            END IF;
    
            IF P_HUESPEDES IS NULL OR P_HUESPEDES <= 0 THEN
                RAISE_APPLICATION_ERROR(-20011,
                    'La cantidad de huespedes debe ser mayor que cero.');
            END IF;
    
            BEGIN
                SELECT CAPACIDAD
                INTO V_CAPACIDAD
                FROM HABITACION
                WHERE ID_HABITACION = P_ID_HABITACION;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    RAISE_APPLICATION_ERROR(-20012,
                        'La habitacion indicada no existe.');
            END;
    
            IF P_HUESPEDES > V_CAPACIDAD THEN
                RAISE_APPLICATION_ERROR(-20013,
                    'La cantidad de huespedes supera la capacidad de la habitacion.');
            END IF;
    
            SELECT COUNT(*)
            INTO V_CLIENTE
            FROM CLIENTE
            WHERE ID_CLIENTE = P_ID_CLIENTE;
    
            IF V_CLIENTE = 0 THEN
                RAISE_APPLICATION_ERROR(-20015,
                    'El cliente indicado no existe.');
            END IF;
    
            SELECT COUNT(*)
            INTO V_OCUPADA
            FROM RESERVA_HABITACION RH
            JOIN RESERVA R ON R.ID_RESERVA = RH.ID_RESERVA
            WHERE RH.ID_HABITACION = P_ID_HABITACION
              AND R.ESTADO IN ('Confirmada', 'Pendiente')
              AND RH.FECHA_CHECKIN < TRUNC(P_FECHA_OUT)
              AND RH.FECHA_CHECKOUT > TRUNC(P_FECHA_IN);
    
            IF V_OCUPADA > 0 THEN
                RAISE_APPLICATION_ERROR(-20014,
                    'La habitacion no esta disponible para las fechas indicadas.');
            END IF;
    
            INSERT INTO RESERVA (
                ID_CLIENTE, FECHA_CHECKIN, FECHA_CHECKOUT, ESTADO
            ) VALUES (
                P_ID_CLIENTE, TRUNC(P_FECHA_IN), TRUNC(P_FECHA_OUT), 'Pendiente'
            )
            RETURNING ID_RESERVA INTO P_ID_RESERVA;
    
            INSERT INTO RESERVA_HABITACION (
                ID_RESERVA, ID_HABITACION, FECHA_CHECKIN, FECHA_CHECKOUT,
                CANTIDAD_HUESPEDES
            ) VALUES (
                P_ID_RESERVA, P_ID_HABITACION, TRUNC(P_FECHA_IN),
                TRUNC(P_FECHA_OUT), P_HUESPEDES
            );
        END SP_CREAR_RESERVA;
    
    END PKG_TURISMO;
    /
    
    -- 3. Comprobación de compilación.
    SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
    FROM USER_OBJECTS
    WHERE OBJECT_NAME = 'PKG_TURISMO'
    ORDER BY OBJECT_TYPE;
    

