#!/bin/bash
# Diagnóstico completo post-cambio de Nginx

echo "============================================"
echo "DIAGNOSTICO POST-CAMBIO DE NGINX"
echo "============================================"
echo ""

CONFIG_FILE="/etc/nginx/sites-available/web-intranet.mpdtucuman.gob.ar"

# 1. Verificar que el archivo tiene el cambio correcto
echo "=== 1. Verificando configuración actual ==="
echo "Buscando la línea con proxy_pass en API PRODUCCIÓN:"
grep -A 5 "API PRODUCCIÓN: REGLA GENERAL" "$CONFIG_FILE" | grep -A 3 "location"
echo ""

# Verificar específicamente si tiene /api/ al final
if grep "proxy_pass http://localhost:3000/api/" "$CONFIG_FILE" > /dev/null; then
    echo "✓ OK - El cambio se aplicó correctamente: proxy_pass http://localhost:3000/api/"
else
    echo "✗ ERROR - El cambio NO se aplicó. Línea actual:"
    grep "proxy_pass http://localhost:3000" "$CONFIG_FILE"
    echo ""
    echo "ACCIÓN: Edita manualmente con:"
    echo "sudo nano $CONFIG_FILE"
    echo "Busca 'proxy_pass http://localhost:3000' y cambia a 'proxy_pass http://localhost:3000/api/'"
fi
echo ""

# 2. Verificar sintaxis de Nginx
echo "=== 2. Verificando sintaxis de Nginx ==="
sudo nginx -t
if [ $? -eq 0 ]; then
    echo "✓ Sintaxis correcta"
else
    echo "✗ ERROR de sintaxis - Nginx NO se puede recargar"
fi
echo ""

# 3. Estado de Nginx
echo "=== 3. Estado del servicio Nginx ==="
sudo systemctl status nginx --no-pager | head -15
echo ""

# 4. Recargar Nginx (por si acaso)
echo "=== 4. Recargando Nginx ==="
sudo systemctl reload nginx
if [ $? -eq 0 ]; then
    echo "✓ Nginx recargado correctamente"
else
    echo "✗ ERROR al recargar Nginx"
fi
sleep 2
echo ""

# 5. Test directo a Express (puerto 3000)
echo "=== 5. Test directo a Express (localhost:3000) ==="
RESPONSE=$(curl -s -X POST http://localhost:3000/api/GrabarActa \
  -H "Content-Type: application/json" \
  -d '{"NroExpediente":"TEST","NroActa":"001","ContenidoActa":"Test"}' \
  -w "\nHTTP_CODE:%{http_code}")
echo "$RESPONSE"
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "500" ]; then
    echo "✓ Express responde correctamente (HTTP $HTTP_CODE)"
else
    echo "✗ Express devuelve HTTP $HTTP_CODE"
fi
echo ""

# 6. Test a través de Nginx HTTP (puerto 80)
echo "=== 6. Test a través de Nginx HTTP (localhost:80) ==="
RESPONSE=$(curl -s -X POST http://localhost/api/GrabarActa \
  -H "Content-Type: application/json" \
  -d '{"NroExpediente":"TEST","NroActa":"001","ContenidoActa":"Test"}' \
  -w "\nHTTP_CODE:%{http_code}")
echo "$RESPONSE"
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "500" ]; then
    echo "✓ Nginx HTTP funciona (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "✗ Nginx HTTP devuelve 404 - El proxy NO esta funcionando"
else
    echo "? HTTP $HTTP_CODE"
fi
echo ""

# 7. Test a través de Nginx HTTPS (puerto 443)
echo "=== 7. Test a través de Nginx HTTPS (localhost:443) ==="
RESPONSE=$(curl -k -s -X POST https://localhost/api/GrabarActa \
  -H "Content-Type: application/json" \
  -d '{"NroExpediente":"TEST","NroActa":"001","ContenidoActa":"Test"}' \
  -w "\nHTTP_CODE:%{http_code}")
echo "$RESPONSE"
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "500" ]; then
    echo "✓ Nginx HTTPS funciona (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "404" ]; then
    echo "✗ Nginx HTTPS devuelve 404 - El proxy NO esta funcionando"
else
    echo "? HTTP $HTTP_CODE"
fi
echo ""

# 8. Logs de error de Nginx
echo "=== 8. Últimos errores de Nginx ==="
sudo tail -30 /var/log/nginx/error.log | grep -i "api\|grabar\|3000" || echo "No hay errores relacionados con la API"
echo ""

# 9. Logs de acceso de Nginx
echo "=== 9. Últimos accesos a /api/ ==="
sudo tail -30 /var/log/nginx/access.log | grep "/api/" | tail -5 || echo "No hay registros de acceso a /api/"
echo ""

echo "============================================"
echo "RESUMEN DEL DIAGNÓSTICO"
echo "============================================"
echo ""
echo "Si Express funciona (test 5) pero Nginx no (tests 6 y 7):"
echo "  -> El problema está en la configuración del proxy_pass"
echo ""
echo "Si todos dan 404:"
echo "  -> Verifica que PM2 esté corriendo y el código tenga el endpoint"
echo ""
echo "SIGUIENTE ACCIÓN:"
echo "1. Si el cambio NO se aplicó -> Editar manualmente el archivo"
echo "2. Si hay error de sintaxis -> Corregir el archivo de configuración"
echo "3. Si Nginx no se recargó -> sudo systemctl restart nginx"
echo "4. Si nada funciona -> Revisar logs completos"
