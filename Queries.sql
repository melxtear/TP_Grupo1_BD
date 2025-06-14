-- Queries.sql

USE `mydb`;

-- a. Un cliente informa que un lote de medicamentos está causando síntomas secundarios en todos sus pacientes. 
-- El análisis arrojó que se debe a un lote de droga XXXX. ¿A quién le tengo que avisar?
-- Supongamos que el lote de droga en cuestión es el que tiene id_droga = 1 (por ejemplo, Acetaminofén).

SELECT DISTINCT
    d.nombre_droga AS droga,                          -- Nombre de la droga asociada al medicamento
    ld.id_Lote_Droga AS id_lote_droga,               -- ID del lote de droga que causó el problema
    p.nombre_proveedor,                              -- Nombre del proveedor responsable
    p.telefono_proveedor,                            -- Teléfono del proveedor
    p.email_proveedor                                -- Correo electrónico del proveedor
FROM 
    lote_medicamento lm                              -- Comenzamos desde el lote de medicamento reportado
JOIN 
    produce pr ON pr.lote_medicamento_id_lote_medicamento = lm.id_lote_medicamento  -- Relaciona con la tabla produce (parte del medicamento)
             AND pr.lote_medicamento_medicamento_id_medicamento = lm.medicamento_id_medicamento  -- Verifica coincidencia del medicamento
JOIN 
    lote_droga ld ON ld.id_Lote_Droga = pr.lote_droga_id_Lote_Droga              -- Lote de droga vinculado
                AND ld.droga_id_droga = pr.lote_droga_droga_id_droga            -- Verifica que sea la misma droga
                AND ld.proveedor_id_proveedor = pr.lote_droga_proveedor_id_proveedor  -- Y que venga del mismo proveedor
JOIN 
    droga d ON d.id_droga = ld.droga_id_droga            -- Se obtiene el nombre de la droga
JOIN 
    proveedor p ON p.id_proveedor = ld.proveedor_id_proveedor  -- Se obtiene la información del proveedor
WHERE 
    lm.id_lote_medicamento = 1;       


-- b) Principal comprador de tal medicamento en 2025
-- Elegimos el medicamento especifico: Paracetamol
SELECT 
    c.nombre_cliente,                                  -- Nombre del cliente
    c.apellido_cliente,                                -- Apellido del cliente
    SUM(v.Cantidad) AS cantidad_comprada               -- Total de unidades compradas por ese cliente
FROM 
    venta v                                            -- Tabla de ventas realizadas
JOIN 
    cliente c ON v.cliente_id_cliente = c.id_cliente   -- Relaciona cada venta con su cliente
JOIN 
    contiene co ON v.id_venta = co.venta_id_venta      -- Relaciona cada venta con los medicamentos que contiene
WHERE 
    co.lote_medicamento_medicamento_id_medicamento = 223  -- Filtra solo el medicamento específico (ej. Paracetamol)
    AND YEAR(v.Fecha_Venta) = 2025                     -- Solo ventas ocurridas en el año 2025
GROUP BY 
    c.id_cliente                                       -- Agrupa los resultados por cliente
ORDER BY 
    cantidad_comprada DESC                             -- Ordena de mayor a menor cantidad comprada
LIMIT 1;


-- c. Consultas adicionales
-- 1. Listar todos los medicamentos y sus respectivos efectos adversos.

SELECT 
    m.nombre AS medicamento,               -- Nombre del medicamento
    m.efectos_adversos                     -- Efectos adversos asociados a ese medicamento
FROM 
    medicamento m;  

-- 2. Mostrar el total de ventas por medicamento en el año 2024.
SELECT 
    m.nombre AS medicamento,                  -- Nombre del medicamento
    SUM(v.Cantidad) AS cantidad_vendida       -- Total de unidades vendidas
FROM 
    venta v
JOIN 
    contiene co ON v.id_venta = co.venta_id_venta  -- Relación entre venta y medicamento
JOIN 
    lote_medicamento lm ON co.lote_medicamento_id_lote_medicamento = lm.id_lote_medicamento
JOIN 
    medicamento m ON lm.medicamento_id_medicamento = m.id_medicamento
WHERE 
    YEAR(v.Fecha_Venta) = 2024                -- Solo se consideran ventas de 2024
GROUP BY 
    m.id_medicamento; 

-- 3. Listar los proveedores y la cantidad de lotes de droga que tienen activos.
SELECT 
    p.nombre_proveedor,   -- Nombre del proveedor
    COUNT(ld.id_Lote_Droga) AS cantidad_lotes_activos -- Cantidad de lotes de droga activos que tiene el proveedor
FROM 
    proveedor p
JOIN 
    lote_droga ld ON p.id_proveedor = ld.proveedor_id_proveedor -- Relaciona proveedores con sus lotes de droga
WHERE 
    ld.estado = 1 -- Filtra solo los lotes de droga que están activos (1 = activo)
GROUP BY 
    p.id_proveedor; -- Agrupa por proveedor para contar sus lotes activos
 
 -- Consulta para listar los clientes que hicieron más de una compra
SELECT 
    c.id_cliente,                           -- ID del cliente
    c.nombre_cliente,                       -- Nombre del cliente
    c.apellido_cliente,                     -- Apellido del cliente
    COUNT(v.id_venta) AS cantidad_compras   -- Número de ventas realizadas
FROM 
    cliente c
JOIN 
    venta v ON c.id_cliente = v.cliente_id_cliente   -- Relación entre cliente y sus ventas
GROUP BY 
    c.id_cliente
HAVING 
    COUNT(v.id_venta) > 1;                 -- Filtra solo los que compraron más de una vez
    
-- Medicamentos que requieren receta, vendidos a clientes particulares
-- Esta consulta muestra todos los medicamentos que requieren receta y que fueron vendidos a clientes particulares.
-- Permite controlar si se está cumpliendo correctamente con la política de receta obligatoria.

SELECT 
    m.nombre AS nombre_medicamento,                 -- Nombre del medicamento
    v.id_venta,                                     -- ID de la venta
    c.nombre_cliente,                               -- Nombre del cliente
    c.apellido_cliente,                             -- Apellido del cliente
    v.Fecha_Venta                                   -- Fecha en la que se realizó la venta
FROM 
    medicamento m
JOIN 
    lote_medicamento lm ON m.id_medicamento = lm.medicamento_id_medicamento
JOIN 
    contiene co ON lm.id_lote_medicamento = co.lote_medicamento_id_lote_medicamento
JOIN 
    venta v ON v.id_venta = co.venta_id_venta
JOIN 
    cliente c ON c.id_cliente = v.cliente_id_cliente
WHERE 
    m.requiere_receta = 1;                          -- Solo medicamentos que requieren receta
    
-- *Proveedor con más devoluciones en el año 2025

SELECT 
    p.nombre_proveedor,                           -- Nombre del proveedor
    SUM(d.cantidad) AS total_devoluciones         -- Total de unidades devueltas
FROM 
    devoluciones d
JOIN 
    proveedor p ON d.id_proveedor = p.id_proveedor
WHERE 
    YEAR(d.fecha_devolucion) = 2025               -- Filtro por año
GROUP BY 
    d.id_proveedor
ORDER BY 
    total_devoluciones DESC
LIMIT 1;

SELECT 
    p.nombre_proveedor,                           -- Nombre del proveedor
    SUM(d.cantidad) AS total_devoluciones         -- Suma total de unidades devueltas por ese proveedor
FROM 
    devoluciones d                                -- Tabla que registra las devoluciones
JOIN 
    proveedor p ON d.id_proveedor = p.id_proveedor -- Se une con la tabla proveedor para obtener su nombre
WHERE 
    YEAR(d.fecha_devolucion) = 2025               -- Filtra solo las devoluciones realizadas en 2025
GROUP BY 
    d.id_proveedor                                 -- Agrupa por proveedor
ORDER BY 
    total_devoluciones DESC                        -- Ordena de mayor a menor según la cantidad devuelta
LIMIT 1;                                           -- Muestra solo el proveedor con más devoluciones

