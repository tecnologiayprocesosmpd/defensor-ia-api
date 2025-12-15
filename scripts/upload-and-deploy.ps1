# Script optimizado para subir la versión compilada al servidor

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "SUBIENDO VERSIÓN COMPILADA AL SERVIDOR" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Configuración
$SERVER = "root@web-intranet.mpdtucuman.gob.ar"
$REMOTE_DIR = "/var/www/web-intranet/defensor-ia/backend"
$LOCAL_DIST = "dist"

# Paso 1: Verificar que exista el directorio dist
if (-not (Test-Path $LOCAL_DIST)) {
    Write-Host "`n✗ Error: No existe el directorio 'dist'" -ForegroundColor Red
    Write-Host "Ejecuta: npm run build" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✓ Directorio dist encontrado" -ForegroundColor Green

# Paso 2: Subir archivos del directorio dist
Write-Host "`nPaso 1: Subiendo archivos desde dist/..." -ForegroundColor Yellow

$filesToUpload = @(
    "index.js",
    "package.json",
    "package-lock.json",
    ".env"
)

foreach ($file in $filesToUpload) {
    $localPath = Join-Path $LOCAL_DIST $file
    
    if (Test-Path $localPath) {
        Write-Host "  Subiendo $file..." -ForegroundColor Gray
        scp $localPath "${SERVER}:${REMOTE_DIR}/"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $file subido" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Error al subir $file" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  ⚠ $file no encontrado, omitiendo..." -ForegroundColor Yellow
    }
}

# Paso 3: Subir scripts SQL y de deployment
Write-Host "`nPaso 2: Subiendo scripts de migración..." -ForegroundColor Yellow

$scriptsToUpload = @(
    "add-firma-biometrica-column.sql",
    "fix-firmaid-column.sql",
    "deploy-firma-endpoints.sh",
    "test-firma-endpoints.sh"
)

foreach ($script in $scriptsToUpload) {
    if (Test-Path $script) {
        Write-Host "  Subiendo $script..." -ForegroundColor Gray
        scp $script "${SERVER}:${REMOTE_DIR}/"
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $script subido" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Error al subir $script" -ForegroundColor Red
        }
    }
}

# Paso 4: Ejecutar deployment en el servidor
Write-Host "`nPaso 3: Ejecutando deployment en el servidor..." -ForegroundColor Yellow

ssh $SERVER @"
cd $REMOTE_DIR
echo "=== Verificando archivos subidos ==="
ls -lh index.js package.json add-firma-biometrica-column.sql

echo ""
echo "=== Instalando dependencias (si es necesario) ==="
npm install --production

echo ""
echo "=== Ejecutando script de deployment ==="
chmod +x deploy-firma-endpoints.sh
chmod +x test-firma-endpoints.sh
./deploy-firma-endpoints.sh
"@

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n================================================================" -ForegroundColor Green
    Write-Host "✓ DEPLOYMENT COMPLETADO EXITOSAMENTE" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Green
    Write-Host "`nEndpoints disponibles en:" -ForegroundColor White
    Write-Host "  https://web-intranet.mpdtucuman.gob.ar:3000/api" -ForegroundColor Cyan
    Write-Host "`nEndpoints nuevos:" -ForegroundColor White
    Write-Host "  - GET  /api/ObtenerActa/:actaId" -ForegroundColor Cyan
    Write-Host "  - GET  /api/ObtenerActasPorExpediente/:nroExpediente" -ForegroundColor Cyan
    Write-Host "`nEndpoints actualizados:" -ForegroundColor White
    Write-Host "  - GET  /api/ObtenerActas (incluye FirmaBiometrica)" -ForegroundColor Cyan
    Write-Host "  - POST /api/GrabarActa (acepta FirmaBiometrica)" -ForegroundColor Cyan
} else {
    Write-Host "`n✗ Error durante el deployment" -ForegroundColor Red
    Write-Host "Revisa los logs del servidor para más detalles" -ForegroundColor Yellow
    exit 1
}
