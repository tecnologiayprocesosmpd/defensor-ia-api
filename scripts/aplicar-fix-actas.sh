#!/bin/bash
# Script para aplicar el fix a la tabla actas en el servidor

echo "=== APLICANDO FIX A LA TABLA ACTAS ==="

# Cargar variables de entorno
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo "Conectando a la base de datos: $DB_NAME"
echo "Host: $DB_HOST"
echo "Usuario: $DB_USER"

# Ejecutar el script SQL
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f fix-actas-table.sql

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Fix aplicado exitosamente"
    echo ""
    echo "Ahora la columna ActaId se generará automáticamente"
else
    echo ""
    echo "✗ Error al aplicar el fix"
    exit 1
fi
