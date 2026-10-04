/*
===========================================================
 PROYECTO INTEGRADOR TURISMOUQ
 BASES DE DATOS II - ENTREGA 1

 Script: 03_CONSULTAS.sql

 Consultas de análisis:
 1. PIVOT
 2. ROLLUP/CUBE + GROUPING
 3. RANK + PARTITION BY
 4. LAG
 5. Consulta parametrizada
 6. UNPIVOT
 7. Consulta libre
===========================================================
*/


/* ========================================================
   1. PIVOT
   Cantidad de reservas por municipio y año.

   PIVOT permite convertir los años que aparecen como
   valores de filas en columnas.
   ======================================================== */

SELECT *
FROM (
    SELECT
        m.nombre AS municipio,
        EXTRACT(YEAR FROM r.fecha_checkin) AS anio,
        r.id_reserva
    FROM RESERVA r
    JOIN RESERVA_HABITACION rh
        ON rh.id_reserva = r.id_reserva
    JOIN HABITACION h
        ON h.id_habitacion = rh.id_habitacion
    JOIN ALOJAMIENTO a
        ON a.id_alojamiento = h.id_alojamiento
    JOIN MUNICIPIO m
        ON m.id_municipio = a.id_municipio
)
PIVOT (
    COUNT(id_reserva)
    FOR anio IN (
        2024 AS reservas_2024,
        2025 AS reservas_2025,
        2026 AS reservas_2026
    )
)
ORDER BY municipio;


/* ========================================================
   2. ROLLUP + GROUPING
   Ingresos por municipio y tipo de alojamiento.

   ROLLUP genera automáticamente:
   - detalle por municipio y tipo
   - subtotal por municipio
   - total general

   GROUPING permite identificar si una fila corresponde
   a un subtotal o al total general.
   ======================================================== */

SELECT
    m.nombre AS municipio,
    ta.nombre AS tipo_alojamiento,
    SUM(p.monto) AS ingresos,
    
    GROUPING(m.nombre) AS grouping_municipio,
    GROUPING(ta.nombre) AS grouping_tipo

FROM PAGO p

JOIN RESERVA r
    ON r.id_reserva = p.id_reserva

JOIN RESERVA_HABITACION rh
    ON rh.id_reserva = r.id_reserva

JOIN HABITACION h
    ON h.id_habitacion = rh.id_habitacion

JOIN ALOJAMIENTO a
    ON a.id_alojamiento = h.id_alojamiento

JOIN MUNICIPIO m
    ON m.id_municipio = a.id_municipio

JOIN TIPO_ALOJAMIENTO ta
    ON ta.id_tipo = a.id_tipo

WHERE p.estado = 'Exitoso'

GROUP BY ROLLUP (
    m.nombre,
    ta.nombre
)

ORDER BY
    m.nombre,
    ta.nombre;


/* ========================================================
   3. RANK + PARTITION BY
   Ranking de alojamientos según sus ingresos dentro
   de cada municipio.

   PARTITION BY reinicia el ranking para cada municipio.
   RANK permite comparar los alojamientos sin perder
   el detalle individual.
   ======================================================== */

SELECT
    municipio,
    alojamiento,
    ingresos,

    RANK() OVER (
        PARTITION BY municipio
        ORDER BY ingresos DESC
    ) AS ranking_municipio

FROM (
    SELECT
        m.nombre AS municipio,
        a.nombre AS alojamiento,
        SUM(p.monto) AS ingresos

    FROM PAGO p

    JOIN RESERVA r
        ON r.id_reserva = p.id_reserva

    JOIN RESERVA_HABITACION rh
        ON rh.id_reserva = r.id_reserva

    JOIN HABITACION h
        ON h.id_habitacion = rh.id_habitacion

    JOIN ALOJAMIENTO a
        ON a.id_alojamiento = h.id_alojamiento

    JOIN MUNICIPIO m
        ON m.id_municipio = a.id_municipio

    WHERE p.estado = 'Exitoso'

    GROUP BY
        m.nombre,
        a.nombre
)

ORDER BY
    municipio,
    ranking_municipio;


/* ========================================================
   4. LAG
   Comparación de ingresos entre meses consecutivos.

   LAG permite obtener el valor del periodo anterior
   sin perder la fila del periodo actual.
   ======================================================== */

WITH ingresos_mensuales AS (
    SELECT
        EXTRACT(YEAR FROM p.fecha_pago) AS anio,
        EXTRACT(MONTH FROM p.fecha_pago) AS mes,
        SUM(p.monto) AS ingresos

    FROM PAGO p

    WHERE p.estado = 'Exitoso'

    GROUP BY
        EXTRACT(YEAR FROM p.fecha_pago),
        EXTRACT(MONTH FROM p.fecha_pago)
)

SELECT
    anio,
    mes,
    ingresos,

    LAG(ingresos) OVER (
        ORDER BY anio, mes
    ) AS ingresos_mes_anterior,

    ingresos -
    LAG(ingresos) OVER (
        ORDER BY anio, mes
    ) AS diferencia

FROM ingresos_mensuales

ORDER BY
    anio,
    mes;


/* ========================================================
   5. CONSULTA PARAMETRIZADA
   Reservas de un municipio determinado.

   El municipio NO está escrito directamente en la consulta.
   SQL Developer solicitará el valor de :p_municipio.

   Ejemplo:
   Armenia
   ======================================================== */

SELECT
    r.id_reserva,
    c.nombre AS cliente,
    m.nombre AS municipio,
    a.nombre AS alojamiento,
    r.fecha_checkin,
    r.fecha_checkout,
    r.estado

FROM RESERVA r

JOIN CLIENTE c
    ON c.id_cliente = r.id_cliente

JOIN RESERVA_HABITACION rh
    ON rh.id_reserva = r.id_reserva

JOIN HABITACION h
    ON h.id_habitacion = rh.id_habitacion

JOIN ALOJAMIENTO a
    ON a.id_alojamiento = h.id_alojamiento

JOIN MUNICIPIO m
    ON m.id_municipio = a.id_municipio

WHERE m.nombre = :p_municipio

ORDER BY
    r.fecha_checkin;


/* ========================================================
   6. UNPIVOT
   Convertir columnas nuevamente en filas.

   Primero construimos una tabla con la cantidad de
   reservas de 2024, 2025 y 2026 por municipio.
   Después UNPIVOT convierte esas tres columnas en filas.

   Resultado:
   municipio | anio | cantidad_reservas
   ======================================================== */

SELECT
    municipio,
    anio,
    cantidad_reservas

FROM (
    SELECT
        m.nombre AS municipio,

        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM r.fecha_checkin) = 2024
                THEN 1
                ELSE 0
            END
        ) AS reservas_2024,

        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM r.fecha_checkin) = 2025
                THEN 1
                ELSE 0
            END
        ) AS reservas_2025,

        SUM(
            CASE
                WHEN EXTRACT(YEAR FROM r.fecha_checkin) = 2026
                THEN 1
                ELSE 0
            END
        ) AS reservas_2026

    FROM RESERVA r

    JOIN RESERVA_HABITACION rh
        ON rh.id_reserva = r.id_reserva

    JOIN HABITACION h
        ON h.id_habitacion = rh.id_habitacion

    JOIN ALOJAMIENTO a
        ON a.id_alojamiento = h.id_alojamiento

    JOIN MUNICIPIO m
        ON m.id_municipio = a.id_municipio

    GROUP BY m.nombre
)

UNPIVOT (
    cantidad_reservas
    FOR anio IN (
        reservas_2024 AS '2024',
        reservas_2025 AS '2025',
        reservas_2026 AS '2026'
    )
)


ORDER BY
    municipio,
    anio;


/* ========================================================
   7. CONSULTA LIBRE
   Ocupación promedio por tipo de alojamiento.

   Permite analizar cuántos huéspedes se manejan en
   promedio según el tipo de alojamiento.
   ======================================================== */

SELECT
    ta.nombre AS tipo_alojamiento,
    COUNT(rh.id_reserva_habitacion) AS habitaciones_reservadas,
    SUM(rh.cantidad_huespedes) AS total_huespedes,
    ROUND(
        AVG(rh.cantidad_huespedes),
        2
    ) AS promedio_huespedes

FROM RESERVA_HABITACION rh

JOIN HABITACION h
    ON h.id_habitacion = rh.id_habitacion

JOIN ALOJAMIENTO a
    ON a.id_alojamiento = h.id_alojamiento

JOIN TIPO_ALOJAMIENTO ta
    ON ta.id_tipo = a.id_tipo

GROUP BY
    ta.nombre

ORDER BY
    promedio_huespedes DESC;


/*
===========================================================
 FIN DE 03_CONSULTAS.sql
===========================================================
*/