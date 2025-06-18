-- =============================================
-- PROYECTO DE LIMPIEZA DE DATOS DE EMPLEADOS
-- Autor: Carlos Nazareno Rolon
-- Fecha: 17/06/2025
-- Base de Datos: MySQL
-- =============================================

-- =============================================
-- ETAPA 1: CONFIGURACIÓN INICIAL
-- =============================================

-- Crear base de datos y configurar entornos
CREATE DATABASE IF NOT EXISTS clean_employee_data;
USE clean_employee_data;

-- Configurar modo seguro para permitir actualizaciones
SET sql_safe_updates = 0;

-- Crear procedimiento para visualizar datos rapidamente
DELIMITER //
CREATE PROCEDURE ShowEmp()
BEGIN
    SELECT * FROM limpieza;
END //
DELIMITER ;

-- =============================================
-- ETAPA 2: EXPLORACIÓN INICIAL DE DATOS
-- =============================================

-- Visualizar estructura y primeros registros
DESCRIBE limpieza;
CALL SHOWEMP();

-- contar total de registros
SELECT COUNT(*) AS total_registros FROM limpieza;

-- =============================================
-- ETAPA 3: LIMPIEZA DE ESTRUCTURA DE COLUMNAS
-- =============================================

-- Renombrar columnas con caracteres especiales y mejorar nombres
ALTER TABLE limpieza CHANGE COLUMN `id_empleado` `id_empleado` VARCHAR(20) NULL;
ALTER TABLE limpieza CHANGE COLUMN `name` `nombre` VARCHAR(100) NULL;
ALTER TABLE limpieza CHANGE COLUMN `apellido` `apellido` VARCHAR(100) NULL;
ALTER TABLE limpieza CHANGE COLUMN `birth_date` `fecha_nacimiento` VARCHAR(50) NULL;
ALTER TABLE limpieza CHANGE COLUMN `genero` `genero` VARCHAR(20) NULL;
ALTER TABLE limpieza CHANGE COLUMN `area` `area` VARCHAR(50) NULL;
ALTER TABLE limpieza CHANGE COLUMN `salary` `salario` VARCHAR(50) NULL;
ALTER TABLE limpieza CHANGE COLUMN `fecha_inicio` `fecha_inicio` VARCHAR(50) NULL;
ALTER TABLE limpieza CHANGE COLUMN `finish_date` `fecha_finalizacion` VARCHAR(50) NULL;
ALTER TABLE limpieza CHANGE COLUMN `expiration_date` `fecha_vencimiento` VARCHAR(50) NULL;
ALTER TABLE limpieza CHANGE COLUMN `type` `tipo_trabajo` VARCHAR(20) NULL;

ALTER TABLE limpieza DROP COLUMN `promotion_date`;


-- mostrar estructura actualizada
DESCRIBE limpieza;

-- =============================================
-- ETAPA 4: IDENTIFICACION Y ELIMINACION DE DUPLICADOS
-- =============================================

-- Identificar registrados diplicados por ID empleado
SELECT id_empleado, COUNT(*) as cantidad_duplicados
FROM limpieza
GROUP BY id_empleado
HAVING COUNT(*) > 1
ORDER BY cantidad_duplicados DESC;

-- Contar total de duplicados
SELECT COUNT(*) AS total_duplicados
FROM (
	SELECT id_empleado
    FROM limpieza
    GROUP BY id_empleado
    HAVING COUNT(*) > 1
) as duplicados;

-- Crear respaldo de tabla original
CREATE TABLE limpieza_backup AS SELECT * FROM limpieza;

-- Eliminar duplicados manteniendo solo registros únicos
CREATE TEMPORARY TABLE temp_limpieza AS 
SELECT DISTINCT * FROM limpieza;

-- Reemplazar tabla original con datos limpios
DROP TABLE limpieza;
CREATE TABLE limpieza AS SELECT * FROM temp_limpieza;

-- =============================================
-- ETAPA 5: LIMPIEZA DE DATOS DE TEXTO
-- =============================================

CALL SHOWEMP();

-- Identificar nombres con espacios en blanco innecesarios 
SELECT nombre, LENGTH(nombre) as longitud_original, LENGTH(TRIM(nombre)) as longitud_limpia
FROM limpieza
WHERE LENGTH(nombre) != LENGTH(TRIM(nombre));

-- Limpiar espacios en blanco de nombres y apellidos
UPDATE limpieza 
SET nombre = TRIM(nombre),
    apellido = TRIM(apellido)
WHERE LENGTH(nombre) != LENGTH(TRIM(nombre)) 
   OR LENGTH(apellido) != LENGTH(TRIM(apellido));

-- =============================================
-- ETAPA 6: ESTANDARIZACIÓN DE GÉNERO
-- =============================================

-- Revisar valores únicos de género
SELECT genero, COUNT(*) AS frecuencia
FROM limpieza
GROUP BY genero
ORDER BY frecuencia DESC;

-- Estandarizar valores de género
UPDATE limpieza 
SET genero = CASE
    WHEN LOWER(genero) IN ('hombre', 'masculino', 'male', 'm') THEN 'Masculino'
    WHEN LOWER(genero) IN ('mujer', 'femenino', 'female', 'f') THEN 'Femenino'
    ELSE 'Otro'
END;

-- Verificar estandarización
SELECT genero, COUNT(*) AS cantidad
FROM limpieza
GROUP BY genero;

-- =============================================
-- ETAPA 7: ESTANDARIZACIÓN DE TIPO DE TRABAJO
-- =============================================

-- Cambiar tipo de columna para mejor manejo
ALTER TABLE limpieza MODIFY COLUMN tipo_trabajo TEXT;

-- Revisar valores actuales
SELECT tipo_trabajo, COUNT(*) AS frecuencia
FROM limpieza
GROUP BY tipo_trabajo
ORDER BY frecuencia DESC;

-- Convertir códigos numéricos a texto descriptivo
UPDATE limpieza
SET tipo_trabajo = CASE
    WHEN tipo_trabajo = '1' THEN 'Remoto'
    WHEN tipo_trabajo = '0' THEN 'Híbrido'
    ELSE 'Otro'
END;

-- Verificar cambios
SELECT tipo_trabajo, COUNT(*) as cantidad
FROM limpieza
GROUP BY tipo_trabajo;

-- =============================================
-- ETAPA 8: LIMPIEZA Y CONVERSIÓN DE SALARIOS
-- =============================================

-- Mostrar formato actual de salarios
SELECT salario, 
       REPLACE(REPLACE(TRIM(salario), '$', ''), ',', '') AS salario_limpio
FROM limpieza 
LIMIT 10;

 -- Limpiar formato de salarios (eliminar $, comas y espacios)
UPDATE limpieza 
SET salario = REPLACE(REPLACE(REPLACE(TRIM(salario), '$', ''), ',', ''), ' ', '');

-- Convertir a tipo numérico
ALTER TABLE limpieza MODIFY COLUMN salario DECIMAL(10,2) NULL;

-- Verificar conversión y mostrar estadísticas
SELECT 
    MIN(salario) as salario_minimo,
    MAX(salario) as salario_maximo,
    AVG(salario) as salario_promedio,
    COUNT(*) as total_registros
FROM limpieza
WHERE salario IS NOT NULL;


-- =============================================
-- ETAPA 9: ESTANDARIZACIÓN DE FECHAS
-- =============================================

-- Convertir fecha de nacimiento a formato estándar
UPDATE limpieza
SET fecha_nacimiento = CASE 
    WHEN fecha_nacimiento LIKE '%/%' THEN 
        DATE_FORMAT(STR_TO_DATE(fecha_nacimiento, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN fecha_nacimiento LIKE '%-%' AND fecha_nacimiento NOT LIKE '%-%-%' THEN 
        DATE_FORMAT(STR_TO_DATE(fecha_nacimiento, '%m-%d-%Y'), '%Y-%m-%d')
    WHEN fecha_nacimiento LIKE '%-%-%' THEN fecha_nacimiento
    ELSE NULL
END;

-- Convertir a tipo DATE
ALTER TABLE limpieza MODIFY COLUMN fecha_nacimiento DATE;

-- Convertir fecha de inicio
UPDATE limpieza
SET fecha_inicio = CASE 
    WHEN fecha_inicio LIKE '%/%' THEN 
        DATE_FORMAT(STR_TO_DATE(fecha_inicio, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN fecha_inicio LIKE '%-%' AND fecha_inicio NOT LIKE '%-%-%' THEN 
        DATE_FORMAT(STR_TO_DATE(fecha_inicio, '%m-%d-%Y'), '%Y-%m-%d')
    WHEN fecha_inicio LIKE '%-%-%' THEN fecha_inicio
    ELSE NULL
END;

ALTER TABLE limpieza MODIFY COLUMN fecha_inicio DATE;


-- Limpiar fecha de finalización (con timestamp)
UPDATE limpieza
SET fecha_finalizacion = CASE 
    WHEN fecha_finalizacion LIKE '% UTC' THEN 
        STR_TO_DATE(SUBSTRING(fecha_finalizacion, 1, 19), '%Y-%m-%d %H:%i:%s')
    WHEN fecha_finalizacion LIKE '%-%-%' AND fecha_finalizacion LIKE '% %' THEN 
        STR_TO_DATE(SUBSTRING(fecha_finalizacion, 1, 19), '%Y-%m-%d %H:%i:%s')
    ELSE NULL
END;

ALTER TABLE limpieza MODIFY COLUMN fecha_finalizacion DATETIME;

-- =============================================
-- ETAPA 10: CREACIÓN DE CAMPOS CALCULADOS
-- =============================================

-- Agregar columna de edad
ALTER TABLE limpieza ADD COLUMN edad INT;

UPDATE limpieza
SET edad = timestampdiff(YEAR, fecha_nacimiento, CURDATE())
WHERE fecha_nacimiento IS NOT NULL;

-- Agregar columna de años de servicio
ALTER TABLE limpieza ADD COLUMN anos_servicio INT;

UPDATE limpieza
SET anos_servicio = TIMESTAMPDIFF(YEAR, fecha_inicio, 
    COALESCE(fecha_finalizacion, CURDATE()))
WHERE fecha_inicio IS NOT NULL;

-- =============================================
-- ETAPA 11: GENERACIÓN DE EMAILS CORPORATIVOS
-- =============================================
-- Agregar columna de email
ALTER TABLE limpieza ADD COLUMN email_corporativo VARCHAR(100);

-- Generar emails corporativos
UPDATE limpieza 
SET email_corporativo = CONCAT(
    LOWER(SUBSTRING_INDEX(nombre, ' ', 1)), 
    '_', 
    LOWER(SUBSTRING(apellido, 1, 2)), 
    '.', 
    LOWER(SUBSTRING(tipo_trabajo, 1, 2)), 
    '@consulting.com'
)
WHERE nombre IS NOT NULL AND apellido IS NOT NULL;


-- =============================================
-- ETAPA 12: VALIDACIÓN Y CONTROL DE CALIDAD
-- =============================================
-- Verificar estructura final
DESCRIBE limpieza;

-- Mostrar resumen de datos limpios
SELECT 
    COUNT(*) as total_empleados,
    COUNT(DISTINCT id_empleado) as empleados_unicos,
    COUNT(DISTINCT area) as areas_diferentes,
    MIN(fecha_nacimiento) as fecha_nacimiento_mas_antigua,
    MAX(fecha_nacimiento) as fecha_nacimiento_mas_reciente,
    AVG(edad) as edad_promedio,
    AVG(salario) as salario_promedio
FROM limpieza;

-- Verificar registros con datos faltantes
SELECT 
    'Nombres faltantes' as campo, COUNT(*) as cantidad
    FROM limpieza WHERE nombre IS NULL
UNION ALL
SELECT 
    'Apellidos faltantes', COUNT(*)
    FROM limpieza WHERE apellido IS NULL
UNION ALL
SELECT 
    'Salarios faltantes', COUNT(*)
    FROM limpieza WHERE salario IS NULL
UNION ALL
SELECT 
    'Fechas nacimiento faltantes', COUNT(*)
    FROM limpieza WHERE fecha_nacimiento IS NULL;
    
    
-- =============================================
-- ETAPA 13: CONSULTAS ANALÍTICAS FINALES
-- =============================================

-- Empleados activos por área
SELECT 
	area,
    COUNT(*) as empleados_activos, 
    AVG(salario) as salario_promedio_area,
    AVG(edad) as edad_promedio
FROM limpieza
WHERE fecha_finalizacion IS NULL
GROUP BY area
ORDER BY empleados_activos DESC;

-- Distribución por género y área
SELECT 
    area,
    genero,
    COUNT(*) as cantidad,
    AVG(salario) as salario_promedio
FROM limpieza
WHERE fecha_finalizacion IS NULL
GROUP BY area, genero
ORDER BY area, genero;

-- Top 10 empleados por salario
SELECT 
    CONCAT(nombre, ' ', apellido) as nombre_completo,
    area,
    salario,
    tipo_trabajo,
    anos_servicio
FROM limpieza
WHERE salario IS NOT NULL
ORDER BY salario DESC
LIMIT 10;

-- Empleados próximos a jubilarse (65+ años)
SELECT 
    CONCAT(nombre, ' ', apellido) as nombre_completo,
    area,
    edad,
    anos_servicio,
    salario
FROM limpieza
WHERE edad >= 65 AND fecha_finalizacion IS NULL
ORDER BY edad DESC;

-- =============================================
-- LIMPIEZA FINAL
-- =============================================
DROP TABLE IF EXISTS limpieza_backup;
