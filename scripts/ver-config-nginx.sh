# Script para ver y corregir la configuracion de Nginx
# Ejecutar EN EL SERVIDOR

echo "=== CONFIGURACION ACTUAL DE NGINX ==="
echo ""

CONFIG_FILE="/etc/nginx/sites-available/web-intranet.mpdtucuman.gob.ar"

echo "Archivo: $CONFIG_FILE"
echo ""

echo "=== Contenido completo del archivo ==="
cat "$CONFIG_FILE"
echo ""
echo "============================================"
echo ""

echo "=== Seccion con proxy_pass ==="
cat "$CONFIG_FILE" | grep -A 10 -B 5 "proxy_pass"
echo ""
echo "============================================"
echo ""

echo "ANALISIS:"
echo "1. ¿Hay una seccion 'location /api' ?"
if grep -q "location /api" "$CONFIG_FILE"; then
    echo "   SI - Existe configuracion para /api"
else
    echo "   NO - Falta configuracion para /api (ESTE ES EL PROBLEMA)"
fi
echo ""

echo "2. ¿El proxy_pass incluye /api?"
if grep "proxy_pass.*3000/api" "$CONFIG_FILE" > /dev/null; then
    echo "   SI - Redirige correctamente a /api"
else
    echo "   NO - El proxy_pass NO incluye /api"
fi
echo ""

echo "SOLUCION:"
echo "Necesitas agregar o modificar la configuracion para incluir:"
echo ""
echo "location /api {"
echo "    proxy_pass http://localhost:3000/api;"
echo "    proxy_http_version 1.1;"
echo "    proxy_set_header Upgrade \$http_upgrade;"
echo "    proxy_set_header Connection 'upgrade';"
echo "    proxy_set_header Host \$host;"
echo "    proxy_cache_bypass \$http_upgrade;"
echo "    proxy_set_header X-Real-IP \$remote_addr;"
echo "    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;"
echo "    proxy_set_header X-Forwarded-Proto \$scheme;"
echo "}"
echo ""

echo "PASOS PARA EDITAR:"
echo "1. Hacer backup:"
echo "   sudo cp $CONFIG_FILE $CONFIG_FILE.backup"
echo ""
echo "2. Editar el archivo:"
echo "   sudo nano $CONFIG_FILE"
echo ""
echo "3. Agregar la seccion 'location /api' dentro del bloque 'server'"
echo ""
echo "4. Verificar sintaxis:"
echo "   sudo nginx -t"
echo ""
echo "5. Si todo esta bien, recargar nginx:"
echo "   sudo systemctl reload nginx"
echo ""
echo "6. Probar el endpoint:"
echo "   curl -X POST http://localhost/api/GrabarActa -H 'Content-Type: application/json' -d '{\"test\":\"test\"}'"
