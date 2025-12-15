-- Script para corregir el tipo de dato de la columna FirmaID
-- Problema: FirmaID es INTEGER pero necesita ser CHAR/VARCHAR para almacenar hashes

-- Verificar el estado actual de la columna
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'actas'
ORDER BY ordinal_position;

-- Opción 1: Si la columna existe como INTEGER, cambiar el tipo
-- (comentar esta línea si la columna no existe)
ALTER TABLE public.actas 
    ALTER COLUMN "FirmaID" TYPE VARCHAR(64);

-- Opción 2: Si la columna no existe, crearla
-- (descomentar solo si la columna no existe)
-- ALTER TABLE public.actas 
--     ADD COLUMN "FirmaID" VARCHAR(64) NULL;

-- Verificar que el cambio se aplicó correctamente
SELECT 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'actas'
  AND column_name = 'FirmaID';
