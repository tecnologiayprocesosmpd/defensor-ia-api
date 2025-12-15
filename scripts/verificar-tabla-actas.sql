-- Script para verificar la estructura actual de la tabla actas
SELECT 
    column_name AS "Columna", 
    data_type AS "Tipo", 
    character_maximum_length AS "Longitud",
    is_nullable AS "Permite NULL",
    column_default AS "Valor por Defecto"
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'actas'
ORDER BY ordinal_position;
