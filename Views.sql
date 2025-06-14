USE `mydb`;

-- 1. Vista para mostrar todos los medicamentos junto con su tipo y precio
/* muestra una lista completa con su precio mayorista y minorista y su tipo de medicamento. 
permite ver rapidamente que medicamentos hay, su tipo y sus precios
*/
CREATE OR REPLACE VIEW vista_medicamentos AS
SELECT 
    m.id_medicamento,                                               -- ID del medicamento
    m.nombre AS nombre_medicamento,                                 -- Nombre del medicamento
    m.precio_minorista,                                             -- Precio al público
    m.precio_mayorista,                                             -- Precio al por mayor
    CASE                                                            -- Clasifica el tipo de medicamento
        WHEN i.id_medicamento IS NOT NULL THEN 'Inyectable'        -- Si existe en la tabla inyectable
        WHEN cb.id_medicamento IS NOT NULL THEN 'Cápsula Blanda'   -- Si existe en la tabla cápsula blanda
        WHEN comp.id_medicamento IS NOT NULL THEN 'Comprimido'     -- Si existe en la tabla comprimido
        ELSE 'Desconocido'                                          -- Si no está en ninguna, no se conoce el tipo
    END AS tipo_medicamento
FROM 
    medicamento m
LEFT JOIN inyectable i ON m.id_medicamento = i.id_medicamento       -- Posible unión con tipo inyectable
LEFT JOIN capsula_blanda cb ON m.id_medicamento = cb.id_medicamento -- Posible unión con cápsula blanda
LEFT JOIN comprimido comp ON m.id_medicamento = comp.id_medicamento; -- Posible unión con comprimido;

-- 2. Vista para mostrar los lotes de droga con su estado y proveedor
/* muestra todos los lotes de droga que han ingresado, junto con el nombre, el proveedor, su estado (inactivo, activo) y la fecha de ingreso del lote
Sirve para llevar un control de trazabilidad y stock de los lotes conociendo quien las entrego y cuando
*/
CREATE OR REPLACE VIEW vista_lotes_droga AS
SELECT 
    ld.id_Lote_Droga,                                   -- ID del lote de droga
    d.nombre_droga,                                     -- Nombre de la droga
    p.nombre_proveedor,                                 -- Nombre del proveedor asociado
    ld.estado,                                          -- Estado del lote (1: Activo, 0: Inactivo)
    ld.fecha_ingreso_lote_droga                         -- Fecha de ingreso del lote de droga
FROM 
    lote_droga ld
JOIN droga d ON ld.droga_id_droga = d.id_droga          -- Une con la tabla droga para obtener el nombre
JOIN proveedor p ON ld.proveedor_id_proveedor = p.id_proveedor; -- Une con proveedor para su información

-- 3. Vista para mostrar la trazabilidad de los medicamentos y sus lotes de droga
/* relaciona los medicamentos con los lotes de droga que se usaron para fabricarlos
permite saber que droga se uso en que medicamento
*/
CREATE OR REPLACE VIEW vista_trazabilidad AS
SELECT 
    lm.id_lote_medicamento,                             -- ID del lote de medicamento
    m.nombre AS medicamento,                            -- Nombre del medicamento
    ld.id_Lote_Droga,                                   -- ID del lote de droga relacionado
    d.nombre_droga,                                     -- Nombre de la droga utilizada
    lm.fecha_ingreso,                                   -- Fecha de ingreso del lote de medicamento
    lm.estado                                           -- Estado del lote de medicamento
FROM 
    lote_medicamento lm
JOIN medicamento m ON lm.medicamento_id_medicamento = m.id_medicamento -- Une para obtener el nombre del medicamento
JOIN produce pr ON pr.lote_medicamento_id_lote_medicamento = lm.id_lote_medicamento 
               AND pr.lote_medicamento_medicamento_id_medicamento = lm.medicamento_id_medicamento -- Relación con produce
JOIN lote_droga ld ON ld.id_Lote_Droga = pr.lote_droga_id_Lote_Droga 
                 AND ld.droga_id_droga = pr.lote_droga_droga_id_droga 
                 AND ld.proveedor_id_proveedor = pr.lote_droga_proveedor_id_proveedor -- Relación completa con lote_droga
JOIN droga d ON d.id_droga = ld.droga_id_droga;         -- Para obtener el nombre de la droga

-- 4. Vista para mostrar el total de ventas por medicamento (según cantidad vendida)
/* sirve para detectar cuales medicamentos se venden mas
*/
CREATE OR REPLACE VIEW vista_total_ventas AS
SELECT 
    m.nombre AS medicamento,                            -- Nombre del medicamento
    SUM(v.Cantidad) AS cantidad_vendida                 -- Suma de la cantidad de unidades vendidas
FROM 
    venta v
JOIN contiene co ON v.id_venta = co.venta_id_venta      -- Relación entre la venta y los lotes vendidos
JOIN lote_medicamento lm ON co.lote_medicamento_id_lote_medicamento = lm.id_lote_medicamento
JOIN medicamento m ON lm.medicamento_id_medicamento = m.id_medicamento
GROUP BY m.id_medicamento;                              -- Agrupado por medicamento

-- 5. Vista para mostrar los proveedores y la cantidad de lotes de droga que tienen activos
/* sirve para cuan activo esta cada proveedor y si es confiable*/
CREATE OR REPLACE VIEW vista_proveedores_lotes_activos AS
SELECT 
    p.nombre_proveedor,                                 -- Nombre del proveedor
    COUNT(ld.id_Lote_Droga) AS cantidad_lotes_activos  -- Cantidad de lotes activos que tiene ese proveedor
FROM 
    proveedor p
JOIN lote_droga ld ON p.id_proveedor = ld.proveedor_id_proveedor
WHERE 
    ld.estado = 1                                        -- Solo lotes con estado activo
GROUP BY 
    p.id_proveedor;                                     -- Agrupado por proveedor

-- 6. Muestra los clientes que más compraron (por cantidad total de productos adquiridos), ordenados de mayor a menor.
CREATE OR REPLACE VIEW vista_clientes_frecuentes AS
SELECT 
    c.id_cliente,                                        -- ID único del cliente
    c.nombre_cliente,                                    -- Nombre del cliente
    c.apellido_cliente,                                  -- Apellido del cliente
    SUM(v.Cantidad) AS total_productos_comprados         -- Suma de todos los productos comprados por ese cliente
FROM 
    cliente c
JOIN 
    venta v ON c.id_cliente = v.cliente_id_cliente       -- Relaciona cada cliente con sus ventas
GROUP BY 
    c.id_cliente                                          -- Agrupa por cliente
ORDER BY 
    total_productos_comprados DESC;                      -- Ordena de mayor a menor según cantidad de productos comprados
    
-- 7. Vista para mostrar medicamentos que nunca fueron vendidos
CREATE OR REPLACE VIEW vista_medicamentos_no_vendidos AS
SELECT 
    m.id_medicamento,                                    -- ID del medicamento
    m.nombre AS nombre_medicamento                       -- Nombre del medicamento
FROM 
    medicamento m
LEFT JOIN 
    lote_medicamento lm ON m.id_medicamento = lm.medicamento_id_medicamento     -- Relaciona con lotes
LEFT JOIN 
    contiene co ON lm.id_lote_medicamento = co.lote_medicamento_id_lote_medicamento  -- Relaciona los lotes con ventas
WHERE 
    co.venta_id_venta IS NULL;                           -- Filtra los que no aparecen en ninguna venta
