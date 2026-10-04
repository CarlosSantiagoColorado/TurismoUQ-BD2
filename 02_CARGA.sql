/*
===========================================================
 PROYECTO INTEGRADOR TURISMOUQ
 BASES DE DATOS II - ENTREGA 1

 Script: 02_CARGA.sql
 Descripción:
 Carga de datos iniciales y generación del volumen mínimo
 requerido para TurismoUQ.

 Oracle Database 21c XE
===========================================================
*/


/* ========================================================
   1. MUNICIPIOS
   Los 12 municipios reales del Quindío.
   ======================================================== */

INSERT INTO MUNICIPIO (nombre) VALUES ('Armenia');
INSERT INTO MUNICIPIO (nombre) VALUES ('Calarca');
INSERT INTO MUNICIPIO (nombre) VALUES ('Circasia');
INSERT INTO MUNICIPIO (nombre) VALUES ('Filandia');
INSERT INTO MUNICIPIO (nombre) VALUES ('La Tebaida');
INSERT INTO MUNICIPIO (nombre) VALUES ('Montenegro');
INSERT INTO MUNICIPIO (nombre) VALUES ('Quimbaya');
INSERT INTO MUNICIPIO (nombre) VALUES ('Salento');
INSERT INTO MUNICIPIO (nombre) VALUES ('Buenavista');
INSERT INTO MUNICIPIO (nombre) VALUES ('Cordoba');
INSERT INTO MUNICIPIO (nombre) VALUES ('Genova');
INSERT INTO MUNICIPIO (nombre) VALUES ('Pijao');


/* ========================================================
   2. TIPOS DE ALOJAMIENTO
   ======================================================== */

INSERT INTO TIPO_ALOJAMIENTO (nombre, descripcion)
VALUES ('Hotel', 'Alojamiento hotelero tradicional');

INSERT INTO TIPO_ALOJAMIENTO (nombre, descripcion)
VALUES ('Finca cafetera', 'Finca turistica con experiencia cafetera');

INSERT INTO TIPO_ALOJAMIENTO (nombre, descripcion)
VALUES ('Glamping', 'Alojamiento turistico tipo glamping');

INSERT INTO TIPO_ALOJAMIENTO (nombre, descripcion)
VALUES ('Hostal', 'Alojamiento turistico tipo hostal');


/* ========================================================
   3. ALOJAMIENTOS
   60 alojamientos distribuidos de forma desigual.
   
   Distribucion por municipio:
   Armenia       12
   Calarca        9
   Circasia       8
   Filandia       7
   La Tebaida     6
   Montenegro     5
   Quimbaya       4
   Salento        3
   Buenavista     2
   Cordoba        2
   Genova         1
   Pijao          1

   Tipos:
   1-20   Hotel
   21-35  Finca cafetera
   36-50  Glamping
   51-60  Hostal
   ======================================================== */

BEGIN
    FOR i IN 1..60 LOOP

        INSERT INTO ALOJAMIENTO (
            id_municipio,
            id_tipo,
            nombre,
            direccion,
            estrellas,
            telefono,
            correo
        )
        VALUES (
            CASE
                WHEN i <= 12 THEN 1
                WHEN i <= 21 THEN 2
                WHEN i <= 29 THEN 3
                WHEN i <= 36 THEN 4
                WHEN i <= 42 THEN 5
                WHEN i <= 47 THEN 6
                WHEN i <= 51 THEN 7
                WHEN i <= 54 THEN 8
                WHEN i <= 56 THEN 9
                WHEN i <= 58 THEN 10
                WHEN i <= 59 THEN 11
                ELSE 12
            END,

            CASE
                WHEN i <= 20 THEN 1
                WHEN i <= 35 THEN 2
                WHEN i <= 50 THEN 3
                ELSE 4
            END,

            'Alojamiento ' || LPAD(i, 3, '0'),

            'Direccion turistica No. ' || i,

            CASE
                WHEN i <= 20 THEN 3 + MOD(i, 3)
                WHEN i <= 35 THEN 4
                WHEN i <= 50 THEN 4 + MOD(i, 2)
                ELSE 2 + MOD(i, 3)
            END,

            '310555' || LPAD(i, 4, '0'),

            'alojamiento' || i || '@turismouq.com'
        );

    END LOOP;
END;
/


/* ========================================================
   4. HABITACIONES
   EXACTAMENTE 400.

   5 hoteles grandes: 32 habitaciones cada uno = 160
   15 hoteles medianos: 8 habitaciones cada uno = 120
   40 alojamientos pequeños: 3 habitaciones cada uno = 120

   Total = 400
   ======================================================== */

BEGIN
    FOR a IN 1..60 LOOP

        DECLARE
            v_cantidad NUMBER;
        BEGIN

            IF a <= 5 THEN
                v_cantidad := 32;
            ELSIF a <= 20 THEN
                v_cantidad := 8;
            ELSE
                v_cantidad := 3;
            END IF;

            FOR h IN 1..v_cantidad LOOP

                INSERT INTO HABITACION (
                    id_alojamiento,
                    numero,
                    capacidad,
                    tipo,
                    descripcion
                )
                VALUES (
                    a,
                    TO_CHAR(h),
                    CASE
                        WHEN h = 1 THEN 2
                        WHEN MOD(h, 5) = 0 THEN 6
                        WHEN MOD(h, 3) = 0 THEN 4
                        ELSE 3
                    END,
                    CASE
                        WHEN MOD(h, 4) = 0 THEN 'Suite'
                        WHEN MOD(h, 3) = 0 THEN 'Cabaña'
                        WHEN MOD(h, 2) = 0 THEN 'Doble'
                        ELSE 'Sencilla'
                    END,
                    'Habitacion del alojamiento ' || a ||
                    ' numero ' || h
                );

            END LOOP;

        END;

    END LOOP;
END;
/


/* ========================================================
   5. TEMPORADAS
   Tres temporadas por año para 2024, 2025 y 2026.
   ======================================================== */

INSERT INTO TEMPORADA
(nombre, fecha_inicio, fecha_fin, anio)
VALUES
('Alta 2024', DATE '2024-01-01', DATE '2024-03-31', 2024);

INSERT INTO TEMPORADA
(nombre, fecha_inicio, fecha_fin, anio)
VALUES
('Media 2024', DATE '2024-04-01', DATE '2024-08-31', 2024);

INSERT INTO TEMPORADA
(nombre, fecha_inicio, fecha_fin, anio)
VALUES
('Baja 2024', DATE '2024-09-01', DATE '2024-12-31', 2024);

INSERT INTO TEMPORADA
(nombre, fecha_inicio, fecha_fin, anio)
VALUES
('Alta 2025', DATE '2025-01-01', DATE '2025-03-31', 2025);

INSERT INTO TEMPORADA
(nombre, fecha_inicio, fecha_fin, anio)
VALUES
('Media 2025', DATE '2025-04-01', DATE '2025-08-31', 2025);

INSERT INTO TEMPORADA
(nombre, fecha_inicio, fecha_fin, anio)
VALUES
('Baja 2025', DATE '2025-09-01', DATE '2025-12-31', 2025);

INSERT INTO TEMPORADA
(nombre, fecha_inicio, fecha_fin, anio)
VALUES
('Alta 2026', DATE '2026-01-01', DATE '2026-03-31', 2026);

INSERT INTO TEMPORADA
(nombre, fecha_inicio, fecha_fin, anio)
VALUES
('Media 2026', DATE '2026-04-01', DATE '2026-08-31', 2026);

INSERT INTO TEMPORADA
(nombre, fecha_inicio, fecha_fin, anio)
VALUES
('Baja 2026', DATE '2026-09-01', DATE '2026-12-31', 2026);


/* ========================================================
   6. TARIFAS
   Una tarifa por cada combinación HABITACION x TEMPORADA.

   400 habitaciones x 9 temporadas = 3600 tarifas.
   ======================================================== */

BEGIN

    FOR h IN (
        SELECT id_habitacion, capacidad
        FROM HABITACION
    )
    LOOP

        FOR t IN (
            SELECT id_temporada, nombre
            FROM TEMPORADA
        )
        LOOP

            INSERT INTO TARIFA (
                id_habitacion,
                id_temporada,
                valor_noche
            )
            VALUES (
                h.id_habitacion,
                t.id_temporada,
                ROUND(
                    (
                        80000 +
                        (h.capacidad * 25000)
                    )
                    *
                    CASE
                        WHEN t.nombre LIKE 'Alta%' THEN 1.40
                        WHEN t.nombre LIKE 'Media%' THEN 1.15
                        ELSE 1.00
                    END
                )
            );

        END LOOP;

    END LOOP;

END;
/


/* ========================================================
   7. CLIENTES
   3000 clientes.
   Ciudades de origen variadas.
   ======================================================== */

BEGIN

    FOR i IN 1..3000 LOOP

        INSERT INTO CLIENTE (
            documento,
            nombre,
            correo,
            telefono,
            ciudad_origen
        )
        VALUES (
            'DOC' || LPAD(i, 7, '0'),

            'Cliente ' || LPAD(i, 4, '0'),

            'cliente' || i || '@correo.com',

            '320' || LPAD(i, 7, '0'),

            CASE MOD(i, 12)
                WHEN 0 THEN 'Armenia'
                WHEN 1 THEN 'Bogota'
                WHEN 2 THEN 'Medellin'
                WHEN 3 THEN 'Cali'
                WHEN 4 THEN 'Pereira'
                WHEN 5 THEN 'Manizales'
                WHEN 6 THEN 'Ibague'
                WHEN 7 THEN 'Cartagena'
                WHEN 8 THEN 'Barranquilla'
                WHEN 9 THEN 'Bucaramanga'
                WHEN 10 THEN 'Neiva'
                ELSE 'Villavicencio'
            END
        );

    END LOOP;

END;
/


/* ========================================================
   8. SERVICIOS
   30 servicios.
   Dos servicios para cada uno de 15 alojamientos.
   ======================================================== */

BEGIN

    FOR i IN 1..15 LOOP

        DECLARE
            v_alojamiento NUMBER;
        BEGIN

            v_alojamiento :=
                CASE i
                    WHEN 1 THEN 1
                    WHEN 2 THEN 5
                    WHEN 3 THEN 13
                    WHEN 4 THEN 17
                    WHEN 5 THEN 22
                    WHEN 6 THEN 25
                    WHEN 7 THEN 30
                    WHEN 8 THEN 37
                    WHEN 9 THEN 43
                    WHEN 10 THEN 48
                    WHEN 11 THEN 52
                    WHEN 12 THEN 55
                    WHEN 13 THEN 57
                    WHEN 14 THEN 59
                    ELSE 60
                END;

            INSERT INTO SERVICIO (
                id_alojamiento,
                nombre,
                descripcion,
                precio
            )
            VALUES (
                v_alojamiento,
                'Desayuno incluido',
                'Servicio de desayuno para los huespedes',
                30000 + (i * 1500)
            );

            INSERT INTO SERVICIO (
                id_alojamiento,
                nombre,
                descripcion,
                precio
            )
            VALUES (
                v_alojamiento,
                'Tour guiado',
                'Recorrido turistico ofrecido por el alojamiento',
                70000 + (i * 2500)
            );

        END;

    END LOOP;

END;
/


/* ========================================================
   9. RESERVAS
   25000 reservas.

   Estados aproximados:
   Pendiente   10%
   Confirmada  40%
   Completada  30%
   Cancelada   20%

   Las reservas se distribuyen entre 2024-2026.
   ======================================================== */

BEGIN

    FOR i IN 1..25000 LOOP

        DECLARE
            v_fecha_in DATE;
            v_fecha_out DATE;
            v_estado VARCHAR2(20);
        BEGIN

            /*
              Se utilizan ciclos de fechas para evitar que
              todas las reservas caigan en el mismo periodo.
            */

            v_fecha_in :=
                DATE '2024-01-01'
                +
                CASE
                    WHEN i <= 20000 THEN
                        FLOOR((i - 1) / 113) * 6
                        + MOD(i, 3)
                    ELSE
                        FLOOR((i - 20001) / 192) * 6
                        + MOD(i, 3)
                END;

            v_fecha_out :=
                v_fecha_in + 1 + MOD(i, 2);

            v_estado :=
                CASE
                    WHEN MOD(i, 20) < 2 THEN 'Pendiente'
                    WHEN MOD(i, 20) < 10 THEN 'Confirmada'
                    WHEN MOD(i, 20) < 16 THEN 'Completada'
                    ELSE 'Cancelada'
                END;

            INSERT INTO RESERVA (
                id_cliente,
                fecha_checkin,
                fecha_checkout,
                estado
            )
            VALUES (
                MOD(i - 1, 3000) + 1,
                v_fecha_in,
                v_fecha_out,
                v_estado
            );

        END;

    END LOOP;

END;
/


/* ========================================================
   10. RESERVA_HABITACION
   30000 líneas.

   Las primeras 5000 reservas tienen dos habitaciones.
   Las demás tienen una.

   Se distribuyen entre alojamientos con diferentes tamaños.
   ======================================================== */

BEGIN

    FOR i IN 1..25000 LOOP

        DECLARE
            v_alojamiento NUMBER;
            v_total_habitaciones NUMBER;
            v_posicion NUMBER;
            v_room1 NUMBER;
            v_capacidad1 NUMBER;
            v_room2 NUMBER;
            v_capacidad2 NUMBER;
            v_fecha_in DATE;
            v_fecha_out DATE;
        BEGIN

            /*
              Primeras 20000 reservas:
              alojamientos que poseen servicios.

              Últimas 5000:
              otros alojamientos.
            */

            IF i <= 20000 THEN

                v_alojamiento :=
                    CASE MOD(i - 1, 15)
                        WHEN 0 THEN 1
                        WHEN 1 THEN 5
                        WHEN 2 THEN 13
                        WHEN 3 THEN 17
                        WHEN 4 THEN 22
                        WHEN 5 THEN 25
                        WHEN 6 THEN 30
                        WHEN 7 THEN 37
                        WHEN 8 THEN 43
                        WHEN 9 THEN 48
                        WHEN 10 THEN 52
                        WHEN 11 THEN 55
                        WHEN 12 THEN 57
                        WHEN 13 THEN 59
                        ELSE 60
                    END;

            ELSE

                v_alojamiento :=
                    CASE MOD(i - 20001, 15)
                        WHEN 0 THEN 2
                        WHEN 1 THEN 3
                        WHEN 2 THEN 4
                        WHEN 3 THEN 6
                        WHEN 4 THEN 7
                        WHEN 5 THEN 8
                        WHEN 6 THEN 9
                        WHEN 7 THEN 10
                        WHEN 8 THEN 11
                        WHEN 9 THEN 12
                        WHEN 10 THEN 14
                        WHEN 11 THEN 15
                        WHEN 12 THEN 16
                        WHEN 13 THEN 18
                        ELSE 19
                    END;

            END IF;


            SELECT COUNT(*)
            INTO v_total_habitaciones
            FROM HABITACION
            WHERE id_alojamiento = v_alojamiento;


            v_posicion :=
                MOD(
                    CASE
                        WHEN i <= 20000 THEN i - 1
                        ELSE i - 20001
                    END,
                    v_total_habitaciones
                ) + 1;


            SELECT id_habitacion,
                   capacidad
            INTO v_room1,
                 v_capacidad1
            FROM (
                SELECT id_habitacion,
                       capacidad,
                       ROW_NUMBER() OVER (
                           ORDER BY id_habitacion
                       ) AS rn
                FROM HABITACION
                WHERE id_alojamiento = v_alojamiento
            )
            WHERE rn = v_posicion;


            SELECT fecha_checkin,
                   fecha_checkout
            INTO v_fecha_in,
                 v_fecha_out
            FROM RESERVA
            WHERE id_reserva = i;


            INSERT INTO RESERVA_HABITACION (
                id_reserva,
                id_habitacion,
                fecha_checkin,
                fecha_checkout,
                cantidad_huespedes
            )
            VALUES (
                i,
                v_room1,
                v_fecha_in,
                v_fecha_out,
                1 + MOD(i, v_capacidad1)
            );


            /*
              5000 reservas con una segunda habitación.
            */

            IF i <= 5000 THEN

                SELECT id_habitacion,
                       capacidad
                INTO v_room2,
                     v_capacidad2
                FROM (
                    SELECT id_habitacion,
                           capacidad
                    FROM HABITACION
                    WHERE id_alojamiento = v_alojamiento
                      AND id_habitacion <> v_room1
                    ORDER BY id_habitacion
                )
                WHERE ROWNUM = 1;


                INSERT INTO RESERVA_HABITACION (
                    id_reserva,
                    id_habitacion,
                    fecha_checkin,
                    fecha_checkout,
                    cantidad_huespedes
                )
                VALUES (
                    i,
                    v_room2,
                    v_fecha_in,
                    v_fecha_out,
                    1 + MOD(i + 1, v_capacidad2)
                );

            END IF;

        END;

    END LOOP;

END;
/


/* ========================================================
   11. PAGOS
   30000 pagos.

   Todas las reservas tienen al menos un pago.
   Las primeras 5000 tienen dos pagos.
   ======================================================== */

BEGIN

    FOR i IN 1..25000 LOOP

        DECLARE
            v_estado_reserva VARCHAR2(20);
            v_estado_pago VARCHAR2(20);
            v_monto NUMBER(12,2);
        BEGIN

            SELECT estado
            INTO v_estado_reserva
            FROM RESERVA
            WHERE id_reserva = i;

            v_estado_pago :=
                CASE
                    WHEN v_estado_reserva = 'Cancelada'
                        THEN 'Reembolsado'
                    WHEN v_estado_reserva = 'Pendiente'
                        THEN 'Pendiente'
                    ELSE 'Exitoso'
                END;

            v_monto :=
                ROUND(
                    150000 +
                    DBMS_RANDOM.VALUE(0, 650000),
                    2
                );

            INSERT INTO PAGO (
                id_reserva,
                fecha_pago,
                monto,
                metodo,
                estado
            )
            VALUES (
                i,
                DATE '2024-01-01' + MOD(i * 17, 1000),
                v_monto,
                CASE MOD(i, 5)
                    WHEN 0 THEN 'Tarjeta de credito'
                    WHEN 1 THEN 'Tarjeta debito'
                    WHEN 2 THEN 'PSE'
                    WHEN 3 THEN 'Transferencia'
                    ELSE 'Efectivo'
                END,
                v_estado_pago
            );


            IF i <= 5000 THEN

                INSERT INTO PAGO (
                    id_reserva,
                    fecha_pago,
                    monto,
                    metodo,
                    estado
                )
                VALUES (
                    i,
                    DATE '2024-01-15' + MOD(i * 13, 900),
                    ROUND(
                        50000 +
                        DBMS_RANDOM.VALUE(0, 250000),
                        2
                    ),
                    CASE MOD(i + 1, 5)
                        WHEN 0 THEN 'Tarjeta de credito'
                        WHEN 1 THEN 'Tarjeta debito'
                        WHEN 2 THEN 'PSE'
                        WHEN 3 THEN 'Transferencia'
                        ELSE 'Efectivo'
                    END,
                    v_estado_pago
                );

            END IF;

        END;

    END LOOP;

END;
/


/* ========================================================
   12. RESERVA_SERVICIO
   EXACTAMENTE 40000 líneas.

   Las primeras 20000 reservas tienen dos servicios.
   ======================================================== */

BEGIN

    FOR i IN 1..20000 LOOP

        DECLARE
            v_alojamiento NUMBER;
            v_servicio1 NUMBER;
            v_servicio2 NUMBER;
            v_precio1 NUMBER(12,2);
            v_precio2 NUMBER(12,2);
        BEGIN

            v_alojamiento :=
                CASE MOD(i - 1, 15)
                    WHEN 0 THEN 1
                    WHEN 1 THEN 5
                    WHEN 2 THEN 13
                    WHEN 3 THEN 17
                    WHEN 4 THEN 22
                    WHEN 5 THEN 25
                    WHEN 6 THEN 30
                    WHEN 7 THEN 37
                    WHEN 8 THEN 43
                    WHEN 9 THEN 48
                    WHEN 10 THEN 52
                    WHEN 11 THEN 55
                    WHEN 12 THEN 57
                    WHEN 13 THEN 59
                    ELSE 60
                END;


            SELECT MIN(id_servicio),
                   MAX(id_servicio)
            INTO v_servicio1,
                 v_servicio2
            FROM SERVICIO
            WHERE id_alojamiento = v_alojamiento;


            SELECT precio
            INTO v_precio1
            FROM SERVICIO
            WHERE id_servicio = v_servicio1;


            SELECT precio
            INTO v_precio2
            FROM SERVICIO
            WHERE id_servicio = v_servicio2;


            INSERT INTO RESERVA_SERVICIO (
                id_reserva,
                id_servicio,
                cantidad,
                precio_unitario
            )
            VALUES (
                i,
                v_servicio1,
                1 + MOD(i, 3),
                v_precio1
            );


            INSERT INTO RESERVA_SERVICIO (
                id_reserva,
                id_servicio,
                cantidad,
                precio_unitario
            )
            VALUES (
                i,
                v_servicio2,
                1 + MOD(i + 1, 2),
                v_precio2
            );

        END;

    END LOOP;

END;
/


/* ========================================================
   13. RESENAS
   3000 reseñas.

   Existen 7500 reservas completadas.
   Se generan reseñas para más del 40 % de ellas.
   ======================================================== */

BEGIN

    FOR r IN (
        SELECT id_reserva,
               id_cliente
        FROM RESERVA
        WHERE estado = 'Completada'
          AND ROWNUM <= 3000
    )
    LOOP

        DECLARE
            v_alojamiento NUMBER;
        BEGIN

            SELECT h.id_alojamiento
            INTO v_alojamiento
            FROM RESERVA_HABITACION rh
            JOIN HABITACION h
              ON h.id_habitacion = rh.id_habitacion
            WHERE rh.id_reserva = r.id_reserva
              AND ROWNUM = 1;


            INSERT INTO RESENA (
                id_cliente,
                id_alojamiento,
                calificacion,
                comentario,
                fecha_resena
            )
            VALUES (
                r.id_cliente,
                v_alojamiento,
                1 + MOD(r.id_reserva, 5),
                CASE MOD(r.id_reserva, 5)
                    WHEN 0 THEN 'Excelente experiencia'
                    WHEN 1 THEN 'Muy buena atencion'
                    WHEN 2 THEN 'Buena experiencia'
                    WHEN 3 THEN 'Experiencia aceptable'
                    ELSE 'Puede mejorar'
                END,
                DATE '2024-01-01' + MOD(r.id_reserva * 11, 1000)
            );

        END;

    END LOOP;

END;
/


/* ========================================================
   14. USUARIOS DEL SISTEMA
   2 administradores
   8 encargados
   Al menos un encargado por tipo de alojamiento.
   ======================================================== */

INSERT INTO USUARIO_SISTEMA (
    id_alojamiento,
    nombre_usuario,
    nombre_completo,
    correo,
    rol,
    estado
)
VALUES (
    NULL,
    'admin1',
    'Administrador Principal',
    'admin1@turismouq.com',
    'Administrador',
    'Activo'
);

INSERT INTO USUARIO_SISTEMA (
    id_alojamiento,
    nombre_usuario,
    nombre_completo,
    correo,
    rol,
    estado
)
VALUES (
    NULL,
    'admin2',
    'Administrador Secundario',
    'admin2@turismouq.com',
    'Administrador',
    'Activo'
);


/* Encargado de cada tipo */

INSERT INTO USUARIO_SISTEMA VALUES (
    DEFAULT, 1, 'encargado1', 'Encargado Hotel',
    'encargado1@turismouq.com', 'Encargado', 'Activo'
);

INSERT INTO USUARIO_SISTEMA VALUES (
    DEFAULT, 21, 'encargado2', 'Encargado Finca',
    'encargado2@turismouq.com', 'Encargado', 'Activo'
);

INSERT INTO USUARIO_SISTEMA VALUES (
    DEFAULT, 36, 'encargado3', 'Encargado Glamping',
    'encargado3@turismouq.com', 'Encargado', 'Activo'
);

INSERT INTO USUARIO_SISTEMA VALUES (
    DEFAULT, 51, 'encargado4', 'Encargado Hostal',
    'encargado4@turismouq.com', 'Encargado', 'Activo'
);


/* Cuatro encargados adicionales */

INSERT INTO USUARIO_SISTEMA VALUES (
    DEFAULT, 3, 'encargado5', 'Encargado Hotel 2',
    'encargado5@turismouq.com', 'Encargado', 'Activo'
);

INSERT INTO USUARIO_SISTEMA VALUES (
    DEFAULT, 23, 'encargado6', 'Encargado Finca 2',
    'encargado6@turismouq.com', 'Encargado', 'Activo'
);

INSERT INTO USUARIO_SISTEMA VALUES (
    DEFAULT, 38, 'encargado7', 'Encargado Glamping 2',
    'encargado7@turismouq.com', 'Encargado', 'Activo'
);

INSERT INTO USUARIO_SISTEMA VALUES (
    DEFAULT, 53, 'encargado8', 'Encargado Hostal 2',
    'encargado8@turismouq.com', 'Encargado', 'Activo'
);


/* ========================================================
   15. CONFIRMAR TODOS LOS CAMBIOS
   ======================================================== */

COMMIT;


/*
===========================================================
 FIN DE 02_CARGA.sql
===========================================================
*/

SELECT 'MUNICIPIO' tabla, COUNT(*) cantidad FROM MUNICIPIO
UNION ALL
SELECT 'TIPO_ALOJAMIENTO', COUNT(*) FROM TIPO_ALOJAMIENTO
UNION ALL
SELECT 'ALOJAMIENTO', COUNT(*) FROM ALOJAMIENTO
UNION ALL
SELECT 'HABITACION', COUNT(*) FROM HABITACION
UNION ALL
SELECT 'TEMPORADA', COUNT(*) FROM TEMPORADA
UNION ALL
SELECT 'TARIFA', COUNT(*) FROM TARIFA
UNION ALL
SELECT 'CLIENTE', COUNT(*) FROM CLIENTE
UNION ALL
SELECT 'RESERVA', COUNT(*) FROM RESERVA
UNION ALL
SELECT 'RESERVA_HABITACION', COUNT(*) FROM RESERVA_HABITACION
UNION ALL
SELECT 'PAGO', COUNT(*) FROM PAGO
UNION ALL
SELECT 'SERVICIO', COUNT(*) FROM SERVICIO
UNION ALL
SELECT 'RESERVA_SERVICIO', COUNT(*) FROM RESERVA_SERVICIO
UNION ALL
SELECT 'RESENA', COUNT(*) FROM RESENA
UNION ALL
SELECT 'USUARIO_SISTEMA', COUNT(*) FROM USUARIO_SISTEMA;

