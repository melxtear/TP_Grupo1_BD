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
