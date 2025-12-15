#!/bin/bash
# Script de despliegue completo para endpoints de firmas biométricas

echo "================================================================"
echo "DESPLIEGUE DE ENDPOINTS DE FIRMAS BIOMÉTRICAS"
echo "================================================================"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Paso 1: Aplicar migración de base de datos
echo -e "\n${YELLOW}Paso 1: Aplicando migración de base de datos...${NC}"
psql -h localhost -U postgres -d defensoria_ia -f add-firma-biometrica-column.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Migración aplicada exitosamente${NC}"
else
    echo -e "${RED}✗ Error al aplicar la migración${NC}"
    exit 1
fi

# Paso 2: Verificar la estructura de la tabla
echo -e "\n${YELLOW}Paso 2: Verificando estructura de la tabla actas...${NC}"
psql -h localhost -U postgres -d defensoria_ia << 'EOF'
SELECT column_name, data_type, character_maximum_length, is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'actas'
ORDER BY ordinal_position;
EOF

# Paso 3: Reiniciar PM2
echo -e "\n${YELLOW}Paso 3: Reiniciando PM2...${NC}"
pm2 restart defensor-ia-api

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PM2 reiniciado exitosamente${NC}"
else
    echo -e "${RED}✗ Error al reiniciar PM2${NC}"
    exit 1
fi

# Esperar a que el servidor inicie
echo -e "\n${YELLOW}Esperando 3 segundos para que el servidor inicie...${NC}"
sleep 3

# Paso 4: Verificar que el servidor esté activo
echo -e "\n${YELLOW}Paso 4: Verificando estado del servidor...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Servidor activo (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}✗ Servidor no responde correctamente (HTTP $HTTP_CODE)${NC}"
    exit 1
fi

# Paso 5: Tests básicos de los endpoints
echo -e "\n${YELLOW}Paso 5: Probando endpoints...${NC}"

# Test 1: GET /api/ObtenerActas
echo -e "\n${YELLOW}Test 1: GET /api/ObtenerActas${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/ObtenerActas)
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ ObtenerActas funciona (HTTP $HTTP_CODE)${NC}"
else
    echo -e "${RED}✗ ObtenerActas falló (HTTP $HTTP_CODE)${NC}"
fi

# Test 2: GET /api/ObtenerActa/:actaId (probando con ID 999999 para ver el 404)
echo -e "\n${YELLOW}Test 2: GET /api/ObtenerActa/999999 (esperando 404)${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/ObtenerActa/999999)
if [ "$HTTP_CODE" = "404" ]; then
    echo -e "${GREEN}✓ ObtenerActa funciona correctamente (404 para ID inexistente)${NC}"
else
    echo -e "${YELLOW}⚠ ObtenerActa devolvió HTTP $HTTP_CODE (se esperaba 404)${NC}"
fi

# Test 3: POST /api/GrabarActa
echo -e "\n${YELLOW}Test 3: POST /api/GrabarActa (insertar acta de prueba)${NC}"
RESPONSE=$(curl -s -X POST http://localhost:3000/api/GrabarActa \
  -H "Content-Type: application/json" \
  -d '{
    "NroExpediente": "TEST-DEPLOY-001",
    "NroActa": "TEST-'$(date +%s)'",
    "ContenidoActa": "<html><body>Acta de prueba de despliegue</body></html>",
    "FirmaID": "test1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab",
    "FirmaBiometrica": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
  }')

if echo "$RESPONSE" | grep -q "correctamente"; then
    echo -e "${GREEN}✓ GrabarActa funciona correctamente${NC}"
    echo "Respuesta: $RESPONSE"
else
    echo -e "${RED}✗ GrabarActa falló${NC}"
    echo "Respuesta: $RESPONSE"
fi

# Resumen final
echo -e "\n================================================================"
echo -e "${GREEN}DESPLIEGUE COMPLETADO${NC}"
echo "================================================================"
echo -e "\nEndpoints disponibles:"
echo "  - GET  /api/ObtenerActas"
echo "  - GET  /api/ObtenerActa/:actaId"
echo "  - GET  /api/ObtenerActasPorExpediente/:nroExpediente"
echo "  - POST /api/GrabarActa (con soporte para FirmaID y FirmaBiometrica)"
echo ""
echo -e "Para más pruebas, ejecuta: ${YELLOW}./test-firma-endpoints.sh${NC}"
echo "================================================================"
