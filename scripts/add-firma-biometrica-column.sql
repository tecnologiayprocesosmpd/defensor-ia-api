-- Agregar columna FirmaBiometrica para almacenar datos Base64 de la firma
-- Esta columna almacenará la imagen de la firma en formato Base64

-- Verificar columnas actuales
SELECT column_name, data_type, character_maximum_length
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'actas'
ORDER BY ordinal_position;

-- Agregar columna FirmaBiometrica (TEXT para soportar Base64 largo)
ALTER TABLE public.actas 
    ADD COLUMN IF NOT EXISTS "FirmaBiometrica" TEXT NULL;

-- Verificar que se agregó correctamente
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'actas'
  AND column_name IN ('FirmaID', 'FirmaBiometrica');

-- Resultado esperado:
-- FirmaID        | character varying | YES
-- FirmaBiometrica | text             | YES
