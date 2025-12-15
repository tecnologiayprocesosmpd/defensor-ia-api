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
