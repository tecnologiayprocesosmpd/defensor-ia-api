# Comandos para diagnosticar el proxy reverso
# Copiar y pegar EN EL SERVIDOR via SSH

echo "=== DIAGNOSTICO DEL PROXY REVERSO ==="
echo ""

echo "=== 1. Verificar que servidor web esta corriendo ==="
systemctl status apache2 2>/dev/null && echo ">> Apache esta corriendo" || echo "Apache no encontrado"
systemctl status httpd 2>/dev/null && echo ">> httpd esta corriendo" || echo "httpd no encontrado"
systemctl status nginx 2>/dev/null && echo ">> Nginx esta corriendo" || echo "Nginx no encontrado"
echo ""

echo "=== 2. Buscar configuracion de web-intranet ==="
echo "Buscando en Apache..."
find /etc/apache2 -name "*web-intranet*" 2>/dev/null || echo "No se encontro config de Apache"
echo ""
echo "Buscando en Nginx..."
find /etc/nginx -name "*web-intranet*" 2>/dev/null || echo "No se encontro config de Nginx"
echo ""

echo "=== 3. Buscar ProxyPass al puerto 3000 ==="
echo "En Apache:"
grep -r "ProxyPass.*3000" /etc/apache2/ 2>/dev/null || echo "No se encontro ProxyPass en Apache"
echo ""
echo "En Nginx:"
grep -r "proxy_pass.*3000" /etc/nginx/ 2>/dev/null || echo "No se encontro proxy_pass en Nginx"
echo ""

echo "=== 4. Ver sitios habilitados ==="
echo "Apache sites-enabled:"
ls -la /etc/apache2/sites-enabled/ 2>/dev/null || echo "Carpeta no existe"
echo ""
echo "Nginx sites-enabled:"
ls -la /etc/nginx/sites-enabled/ 2>/dev/null || echo "Carpeta no existe"
echo ""

echo "=== 5. Buscar configuracion que mencione 'api' ==="
grep -r "location /api" /etc/nginx/ 2>/dev/null || echo "No se encontro en Nginx"
grep -r "ProxyPass /api" /etc/apache2/ 2>/dev/null || echo "No se encontro en Apache"
echo ""

echo "=== FIN DEL DIAGNOSTICO ==="
echo ""
echo "SIGUIENTE PASO:"
echo "1. Identifica que servidor web estas usando (Apache o Nginx)"
echo "2. Encuentra el archivo de configuracion del sitio web-intranet"
echo "3. Verifica que tenga la redireccion /api -> localhost:3000"
echo "4. Si no existe o esta mal, necesitas editarla"
