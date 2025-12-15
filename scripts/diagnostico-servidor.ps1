# Script para diagnosticar el problema en el servidor
# Este script genera comandos que debes ejecutar EN EL SERVIDOR via SSH

Write-Host "=== DIAGNOSTICO DEL SERVIDOR ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Copia y ejecuta estos comandos EN EL SERVIDOR (via SSH):" -ForegroundColor Yellow
Write-Host ""
Write-Host "========================================" -ForegroundColor Gray

$comandos = @"
# 1. Ir al directorio de la aplicacion
cd /var/www/web-intranet/defensor-ia/backend

# 2. Verificar que el archivo index.js tiene el endpoint
echo "=== Verificando endpoint en index.js ==="
grep -n "GrabarActa" index.js
echo ""

# 3. Verificar numero de lineas del archivo
echo "=== Numero de lineas de index.js ==="
wc -l index.js
echo "Debe ser: 396 lineas"
echo ""

# 4. Verificar estado de PM2
echo "=== Estado de PM2 ==="
pm2 status defensor-ia-api
echo ""

# 5. Ver informacion detallada de PM2
echo "=== Info detallada de PM2 ==="
pm2 info defensor-ia-api
echo ""

# 6. Ver logs recientes
echo "=== Logs recientes ==="
pm2 logs defensor-ia-api --lines 30 --nostream
echo ""

# 7. REINICIAR PM2 (IMPORTANTE)
echo "=== Reiniciando PM2 ==="
pm2 restart defensor-ia-api
echo ""

# 8. Esperar 3 segundos
sleep 3

# 9. Ver logs despues del reinicio
echo "=== Logs despues del reinicio ==="
pm2 logs defensor-ia-api --lines 20 --nostream
echo ""

# 10. Test local del endpoint
echo "=== Test del endpoint (GET - debe dar 404 o 405) ==="
curl -i http://localhost:3000/api/GrabarActa
echo ""

# 11. Test local del endpoint (POST)
echo "=== Test del endpoint (POST) ==="
curl -X POST http://localhost:3000/api/GrabarActa \
  -H "Content-Type: application/json" \
  -d '{"NroExpediente":"TEST","NroActa":"001","ContenidoActa":"Test"}' \
  -w "\nHTTP_CODE: %{http_code}\n"
echo ""

echo "=== FIN DEL DIAGNOSTICO ==="
"@

Write-Host $comandos -ForegroundColor White
Write-Host ""
Write-Host "========================================" -ForegroundColor Gray
Write-Host ""
Write-Host "INSTRUCCIONES:" -ForegroundColor Yellow
Write-Host "1. Abre una terminal SSH al servidor" -ForegroundColor White
Write-Host "2. Copia y pega TODOS los comandos de arriba" -ForegroundColor White
Write-Host "3. Revisa la salida y busca:" -ForegroundColor White
Write-Host "   - Que index.js tenga 396 lineas" -ForegroundColor Gray
Write-Host "   - Que aparezca 'GrabarActa' en la linea 339" -ForegroundColor Gray
Write-Host "   - Que PM2 este en estado 'online'" -ForegroundColor Gray
Write-Host "   - Que el test POST NO de 404" -ForegroundColor Gray
Write-Host ""

# Guardar comandos en un archivo
$comandos | Out-File -FilePath "comandos-servidor.sh" -Encoding UTF8
Write-Host "Los comandos tambien se guardaron en: comandos-servidor.sh" -ForegroundColor Green
Write-Host ""
