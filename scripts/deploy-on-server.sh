#!/bin/bash
# Script para ejecutar EN EL SERVIDOR después de subir los archivos
# Guarda este archivo y ejecútalo en el servidor

set -e  # Salir si hay algún error

echo "=== DEPLOYMENT DE DEFENSOR-IA-API ==="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuración
APP_DIR="/var/www/web-intranet/defensor-ia/backend"
APP_NAME="defensor-ia-api"

echo -e "${CYAN}Paso 1: Ir al directorio de la aplicación${NC}"
cd "$APP_DIR"
echo -e "${GREEN}✓ Directorio actual: $(pwd)${NC}"
echo ""

echo -e "${CYAN}Paso 2: Crear backup${NC}"
BACKUP_DIR="../backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp index.js "$BACKUP_DIR/" 2>/dev/null || true
cp .env "$BACKUP_DIR/" 2>/dev/null || true
cp package.json "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✓ Backup creado en: $BACKUP_DIR${NC}"
echo ""

echo -e "${CYAN}Paso 3: Verificar archivos actualizados${NC}"
echo -e "${YELLOW}Verificando endpoint GrabarActa...${NC}"
if grep -q "GrabarActa" index.js; then
    echo -e "${GREEN}✓ Endpoint GrabarActa encontrado en index.js${NC}"
    grep -n "app.post('/api/GrabarActa'" index.js | head -1
else
    echo -e "${RED}✗ ERROR: No se encuentra el endpoint GrabarActa en index.js${NC}"
    echo -e "${RED}  Asegúrate de haber subido el archivo correcto${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Verificando configuración de BD...${NC}"
if grep -q "DB_USER=mpdlectura" .env; then
    echo -e "${GREEN}✓ Usuario de BD correcto: mpdlectura${NC}"
else
    echo -e "${RED}✗ ADVERTENCIA: El usuario de BD no es 'mpdlectura'${NC}"
    echo "Usuario actual:"
    grep "DB_USER=" .env
fi

if grep -q "DB_NAME=Chat_DW_Ejecucion" .env; then
    echo -e "${GREEN}✓ Base de datos correcta: Chat_DW_Ejecucion${NC}"
else
    echo -e "${RED}✗ ADVERTENCIA: La BD no es 'Chat_DW_Ejecucion'${NC}"
    echo "BD actual:"
    grep "DB_NAME=" .env
fi
echo ""

echo -e "${CYAN}Paso 4: Reinstalar dependencias${NC}"
if [ -f "package-lock.json" ]; then
    npm ci --only=production
else
    npm install --production
fi
echo -e "${GREEN}✓ Dependencias instaladas${NC}"
echo ""

echo -e "${CYAN}Paso 5: Reiniciar PM2${NC}"
pm2 restart "$APP_NAME"
echo -e "${GREEN}✓ PM2 reiniciado${NC}"
echo ""

echo -e "${CYAN}Paso 6: Esperar 3 segundos para que inicie...${NC}"
sleep 3
echo ""

echo -e "${CYAN}Paso 7: Verificar estado de PM2${NC}"
pm2 status "$APP_NAME"
echo ""

echo -e "${CYAN}Paso 8: Ver logs recientes${NC}"
echo -e "${YELLOW}Últimas 30 líneas de logs:${NC}"
pm2 logs "$APP_NAME" --lines 30 --nostream
echo ""

echo -e "${CYAN}Paso 9: Test del endpoint${NC}"
echo -e "${YELLOW}Test 1: Health check${NC}"
HEALTH_RESPONSE=$(curl -s http://localhost:3000/api/health)
if echo "$HEALTH_RESPONSE" | grep -q "UP"; then
    echo -e "${GREEN}✓ Health check OK${NC}"
    echo "$HEALTH_RESPONSE" | grep -o '"version":"[^"]*"'
else
    echo -e "${RED}✗ Health check falló${NC}"
    echo "$HEALTH_RESPONSE"
fi
echo ""

echo -e "${YELLOW}Test 2: Endpoint GrabarActa (POST)${NC}"
GRABAR_RESPONSE=$(curl -s -X POST http://localhost:3000/api/GrabarActa \
    -H "Content-Type: application/json" \
    -d '{"NroExpediente":"TEST","NroActa":"001","ContenidoActa":"Test"}' \
    -w "\nHTTP_CODE:%{http_code}")

HTTP_CODE=$(echo "$GRABAR_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "500" ]; then
    echo -e "${GREEN}✓ Endpoint GrabarActa responde (no es 404)${NC}"
    echo "HTTP Code: $HTTP_CODE"
    echo "$GRABAR_RESPONSE" | grep -v "HTTP_CODE"
else
    echo -e "${RED}✗ Endpoint GrabarActa devuelve: $HTTP_CODE${NC}"
    echo "$GRABAR_RESPONSE" | grep -v "HTTP_CODE"
fi
echo ""

echo -e "${CYAN}Paso 10: Guardar configuración de PM2${NC}"
pm2 save
echo -e "${GREEN}✓ Configuración guardada${NC}"
echo ""

echo -e "${GREEN}=== DEPLOYMENT COMPLETADO ===${NC}"
echo ""
echo -e "${YELLOW}VERIFICACIÓN FINAL:${NC}"
echo "1. Revisa los logs arriba para confirmar que no hay errores"
echo "2. Verifica que el usuario de BD sea 'mpdlectura'"
echo "3. Confirma que el endpoint GrabarActa no devuelve 404"
echo ""
echo -e "${YELLOW}Para ver logs en tiempo real:${NC}"
echo "pm2 logs $APP_NAME"
echo ""
echo -e "${YELLOW}Para ver información detallada:${NC}"
echo "pm2 info $APP_NAME"
