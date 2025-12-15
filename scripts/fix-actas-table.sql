-- Script para arreglar la tabla actas
-- Problema: ActaId es NOT NULL pero no tiene valor por defecto

-- 1. Crear la secuencia si no existe
CREATE SEQUENCE IF NOT EXISTS actas_actaid_seq;

-- 2. Establecer el valor actual de la secuencia al máximo ActaId existente
SELECT setval('actas_actaid_seq', COALESCE((SELECT MAX("ActaId") FROM public.actas), 0));

-- 3. Modificar la columna ActaId para usar la secuencia como valor por defecto
ALTER TABLE public.actas 
  ALTER COLUMN "ActaId" SET DEFAULT nextval('actas_actaid_seq');

-- 4. Hacer que la columna sea SERIAL (asociar la secuencia a la columna)
ALTER SEQUENCE actas_actaid_seq OWNED BY public.actas."ActaId";

-- Verificación
SELECT column_name, data_type, column_default, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'actas' AND table_schema = 'public';
