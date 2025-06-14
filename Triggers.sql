-- -------------------------------------------------------------------------
-- 3.A.1) Trigger para asegurar que un lote de droga salga de cuarentena solo si todos sus análisis son satisfactorios.

drop trigger if exists trg_actualizar_estado_lote_droga;
DELIMITER //

CREATE TRIGGER trg_actualizar_estado_lote_droga
AFTER INSERT ON analisis_d              -- Se ejecuta después de insertar un nuevo registro en la tabla analisis_d
FOR EACH ROW                          -- Por cada fila insertada, se ejecuta el bloque BEGIN...END
BEGIN
  DECLARE cantidad_rechazados INT;  -- Declara una variable para almacenar la cantidad de análisis rechazados para ese lote

  -- Cuenta cuántos análisis con resultado 'rechazado' existen para el lote al que pertenece el nuevo análisis insertado
  SELECT COUNT(*) INTO cantidad_rechazados
  FROM analisis_d
  WHERE lote_droga_id_Lote_Droga = NEW.lote_droga_id_Lote_Droga
    AND resultado_d = 'rechazado';

  -- Si no hay análisis rechazados (cantidad_rechazados = 0), significa que todos los análisis están aprobados
  IF cantidad_rechazados = 0 THEN
    UPDATE lote_droga
    SET estado = 1              -- Cambia el estado del lote a 1 (aprobado / fuera de cuarentena)
    WHERE id_Lote_Droga = NEW.lote_droga_id_Lote_Droga;

  ELSE                         -- Si hay al menos un análisis rechazado
    UPDATE lote_droga
    SET estado = 0              -- Cambia el estado del lote a 0 (en cuarentena)
    WHERE id_Lote_Droga = NEW.lote_droga_id_Lote_Droga;

  END IF;
END
//
DELIMITER ;


/* -- estos insert se usaron para probar el trigger una vez creada la database, descomentar si se quiere probar
-- es para ver si se actualiza de NULL a rechazado o aprobado
-- Caso 1 cambia a aprobado
INSERT INTO mydb.lote_droga (id_Lote_Droga, precio, fecha_ingreso_lote_droga, estado, droga_id_droga, proveedor_id_proveedor) VALUES
(10, 1500, '2025-05-15', NULL, 2, 1);
INSERT INTO mydb.analisis_d
  (analisis_Id_Analisis, lote_droga_id_Lote_Droga, lote_droga_droga_id_droga, lote_droga_proveedor_id_proveedor, resultado_d, fecha_analisis_d) VALUES
(100, 10, 2, 1, 'Aprobado', '2025-06-10');

-- Caso 2 cambia a rechazado
INSERT INTO mydb.lote_droga (id_Lote_Droga, precio, fecha_ingreso_lote_droga, estado, droga_id_droga, proveedor_id_proveedor) VALUES
(11, 1600, '2025-05-20', 0, 3, 2);
INSERT INTO mydb.analisis_d
  (analisis_Id_Analisis, lote_droga_id_Lote_Droga, lote_droga_droga_id_droga, lote_droga_proveedor_id_proveedor, resultado_d, fecha_analisis_d) VALUES
(101, 11, 3, 2, 'Rechazado', '2025-06-11');

-- Casos extra
INSERT INTO mydb.lote_droga (id_Lote_Droga, precio, fecha_ingreso_lote_droga, estado, droga_id_droga, proveedor_id_proveedor) VALUES
(12, 1700, '2025-05-25', 0, 1, 3);

INSERT INTO mydb.analisis_d
  (analisis_Id_Analisis, lote_droga_id_Lote_Droga, lote_droga_droga_id_droga, lote_droga_proveedor_id_proveedor, resultado_d, fecha_analisis_d) VALUES
(102, 12, 1, 3, 'Aprobado', '2025-06-12');

INSERT INTO mydb.lote_droga (id_Lote_Droga, precio, fecha_ingreso_lote_droga, estado, droga_id_droga, proveedor_id_proveedor) VALUES
(13, 1800, '2025-06-01', 0, 2, 2);
INSERT INTO mydb.analisis_d
  (analisis_Id_Analisis, lote_droga_id_Lote_Droga, lote_droga_droga_id_droga, lote_droga_proveedor_id_proveedor, resultado_d, fecha_analisis_d) VALUES
(103, 13, 2, 2, 'Aprobado', '2025-06-13');
*/


-- 3.A.2) Trigger para asegurar que un lote de medicamento salga de cuarentena solo si todos sus análisis son satisfactorios.
DELIMITER //
CREATE TRIGGER trg_actualizar_estado_lote_medicamento AFTER INSERT ON analisis_medicamento
FOR EACH ROW
BEGIN
  DECLARE todos_satisfactorios INT;
  -- Declara una variable para contar cuántos análisis NO son 'Aprobado' para el lote y medicamento recién insertados

  SELECT COUNT(*) INTO todos_satisfactorios
  FROM analisis_medicamento
  WHERE lote_medicamento_id_lote_medicamento = NEW.lote_medicamento_id_lote_medicamento
    AND lote_medicamento_medicamento_id_medicamento = NEW.lote_medicamento_medicamento_id_medicamento
    AND resultado_m <> 'Aprobado';
-- Cuenta cuántos análisis en la tabla para ese lote y medicamento tienen resultado distinto a 'Aprobado'
-- Guarda ese número en la variable todos_satisfactorios

  IF todos_satisfactorios = 0 THEN 
    UPDATE lote_medicamento
    SET estado = 'Activo' -- Si NO hay análisis con resultado distinto a 'Aprobado', pone el lote en estado 'Activo'
    WHERE id_lote_medicamento = NEW.lote_medicamento_id_lote_medicamento;
  ELSE
    UPDATE lote_medicamento
    SET estado = 'Inactivo' -- Si hay al menos un análisis no aprobado, pone el lote en estado 'Inactivo'
    WHERE id_lote_medicamento = NEW.lote_medicamento_id_lote_medicamento;
  END IF;
END
//
DELIMITER

/*-- estos insert se usaron para probar el trigger una vez creada la database, descomentar si se quiere probar
-- Inserción de lotes para probar trigger
INSERT INTO lote_medicamento (id_lote_medicamento, fecha_ingreso, estado, medicamento_id_medicamento) VALUES
(15, '2025-06-01', 'Inactivo', 1),
(20, '2025-06-05', 'Inactivo', 2)

-- inserto mas Medicamentos para probar trigger
INSERT INTO medicamento (id_medicamento, nombre, precio_minorista, precio_mayorista, almacenamiento, via_administración, efectos_adversos, requiere_receta) VALUES
(1, 'Paracetamol', 150, 130, 'Seco', 'Oral', 'Ninguno', 0),
(2, 'Ibuprofeno', 200, 180, 'Seco', 'Oral', 'Náuseas', 0);

-- Análisis para lote 10, todos aprobados entonces lote se pone en activo
INSERT INTO analisis_medicamento (lote_medicamento_id_lote_medicamento, lote_medicamento_medicamento_id_medicamento, analisis_Id_Analisis, resultado_m, fecha_analisis_m) VALUES
(15, 1, 1, 'Aprobado', '2025-06-10'),
(15, 1, 2, 'Aprobado', '2025-06-11');

-- Análisis para lote 20, con uno rechazado entonces el lote va a estar inactivo
INSERT INTO analisis_medicamento (lote_medicamento_id_lote_medicamento, lote_medicamento_medicamento_id_medicamento, analisis_Id_Analisis, resultado_m, fecha_analisis_m) VALUES
(20, 2, 3, 'Rechazado', '2025-06-12'),
(20, 2, 4, 'Aprobado', '2025-06-13');
*/


-- 3.B) Agregar un trigger en la tabla proveedor cuando se hayan devuelto +5 lotes de droga en el año. 
-- Se actualiza en columnas de proveedor (la cantidad y prinicipalmente la columna de devoluciones_mayor_a_5)
DELIMITER //
CREATE TRIGGER trg_update_proveedor_devoluciones
AFTER INSERT ON devoluciones -- Esto se ejecuta automáticamente después de cada inserción de una fila en la tabla devoluciones.
FOR EACH ROW
BEGIN
  DECLARE total_devoluciones INT; -- Declara una variable para almacenar cuántas devoluciones hizo ese proveedor en el año.

  -- Contar cuántas devoluciones hizo ese proveedor (New.id_proveedor) y en el mismo año de la nueva devolución (NEW.fecha_devolucion).
  SELECT COUNT(*) INTO total_devoluciones
  FROM devoluciones
  WHERE id_proveedor = NEW.id_proveedor
    AND YEAR(fecha_devolucion) = YEAR(NEW.fecha_devolucion);

  -- Si hay más de 5, actualiza el campo en proveedor y se marca como 1 (seria como si fuera mal vendedor, ya que nos dio lotes defectuosos, queda registrado en sistema como advertencia)
  IF total_devoluciones > 5 THEN
    UPDATE proveedor
    SET devoluciones_mayor_a_5 = 1
    WHERE id_proveedor = NEW.id_proveedor;
  END IF;

  -- Siempre actualizar la cantidad_devoluciones (total histórico si querés)
  UPDATE proveedor
  SET cantidad_devoluciones = cantidad_devoluciones + 1
  WHERE id_proveedor = NEW.id_proveedor;

END;
//
DELIMITER 
