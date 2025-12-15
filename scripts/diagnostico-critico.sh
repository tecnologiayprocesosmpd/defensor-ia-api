#!/bin/bash
# Script de diagnostico CRITICO para encontrar por que GrabarActa da 404
# Ejecutar EN EL SERVIDOR via SSH

echo "============================================"
echo "DIAGNOSTICO CRITICO - ENDPOINT GrabarActa"
echo "============================================"
echo ""

# 1. Ir al directorio
cd /var/www/web-intranet/defensor-ia/backend
echo "Directorio actual: $(pwd)"
echo ""

# 2. Verificar lineas del archivo
echo "=== VERIFICACION 1: Numero de lineas ==="
LINEAS=$(wc -l < index.js)
echo "Lineas en index.js: $LINEAS"
if [ "$LINEAS" -eq 396 ]; then
    echo "✓ OK - El archivo tiene 396 lineas (correcto)"
else
    echo "✗ ERROR - Deberia tener 396 lineas, tiene $LINEAS"
    echo "  ACCION: El archivo NO se subio correctamente"
fi
echo ""

# 3. Buscar el endpoint
echo "=== VERIFICACION 2: Endpoint GrabarActa ==="
if grep -q "app.post('/api/GrabarActa'" index.js; then
    LINEA=$(grep -n "app.post('/api/GrabarActa'" index.js | cut -d: -f1)
    echo "✓ OK - Endpoint encontrado en linea $LINEA"
    grep -n "app.post('/api/GrabarActa'" index.js
else
    echo "✗ ERROR CRITICO - El endpoint GrabarActa NO EXISTE en index.js"
    echo "  ACCION: Debes subir el archivo correcto"
    echo ""
    echo "Endpoints disponibles en el archivo:"
    grep -n "app.post\|app.get" index.js | head -10
fi
echo ""

# 4. Verificar estado de PM2
echo "=== VERIFICACION 3: Estado de PM2 ==="
pm2 status defensor-ia-api
echo ""

# 5. Info detallada de PM2
echo "=== VERIFICACION 4: Archivo que PM2 esta ejecutando ==="
pm2 info defensor-ia-api | grep -A 5 "script path"
echo ""

# 6. PID del proceso
echo "=== VERIFICACION 5: PID y tiempo de inicio ==="
PM2_INFO=$(pm2 jlist)
echo "$PM2_INFO" | grep -A 10 "defensor-ia-api" | grep -E "pid|pm_uptime"
echo ""

# 7. Reiniciar PM2
echo "=== VERIFICACION 6: Reiniciando PM2 ==="
echo "REINICIANDO PM2 AHORA..."
pm2 restart defensor-ia-api
echo "✓ PM2 reiniciado"
echo ""

# 8. Esperar
echo "Esperando 5 segundos para que inicie..."
sleep 5
echo ""

# 9. Ver logs
echo "=== VERIFICACION 7: Logs recientes ==="
pm2 logs defensor-ia-api --lines 20 --nostream
echo ""

# 10. Test del endpoint
echo "=== VERIFICACION 8: Test del endpoint ==="
echo "Test 1: GET (debe dar 404 o 405, NO timeout)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/GrabarActa)
echo "HTTP Code: $HTTP_CODE"
if [ "$HTTP_CODE" -eq 404 ]; then
    echo "✗ SIGUE DANDO 404 - EL ENDPOINT NO EXISTE"
elif [ "$HTTP_CODE" -eq 405 ]; then
    echo "✓ OK - 405 Method Not Allowed (el endpoint existe)"
else
    echo "? Code inesperado: $HTTP_CODE"
fi
echo ""

echo "Test 2: POST"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST http://localhost:3000/api/GrabarActa \
    -H "Content-Type: application/json" \
    -d '{"NroExpediente":"TEST","NroActa":"001","ContenidoActa":"Test"}')
echo "$RESPONSE"
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
if [ "$HTTP_CODE" -eq 404 ]; then
    echo ""
    echo "✗✗✗ ERROR CRITICO ✗✗✗"
    echo "El endpoint SIGUE dando 404 despues de reiniciar PM2"
    echo ""
    echo "CAUSAS POSIBLES:"
    echo "1. El archivo index.js en el servidor NO tiene el endpoint"
    echo "2. PM2 esta ejecutando un archivo diferente"
    echo "3. Hay un proxy (Apache/Nginx) que no esta redirigiendo"
    echo ""
elif [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 500 ]; then
    echo ""
    echo "✓✓✓ EXITO ✓✓✓"
    echo "El endpoint funciona correctamente!"
fi
echo ""

# 11. Verificar rutas de Express
echo "=== VERIFICACION 9: Todos los endpoints registrados ==="
echo "Buscando todos los POST endpoints en index.js:"
grep -n "app.post" index.js
echo ""

echo "============================================"
echo "FIN DEL DIAGNOSTICO"
echo "============================================"
echo ""
echo "SIGUIENTE ACCION:"
echo "1. Si el endpoint NO existe en index.js -> Subir el archivo correcto"
echo "2. Si el endpoint existe pero sigue dando 404 -> Problema con proxy o PM2"
echo "3. Si funciona -> Probar desde tu PC con test-endpoint.ps1"
