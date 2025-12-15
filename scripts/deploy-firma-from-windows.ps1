# Script de despliegue desde Windows al servidor

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "DESPLIEGUE DE ENDPOINTS DE FIRMAS BIOMÉTRICAS" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Configuración
$SERVER = "root@web-intranet.mpdtucuman.gob.ar"
$REMOTE_DIR = "/var/www/web-intranet/defensor-ia/backend"

# Paso 1: Subir archivos al servidor
Write-Host "`nPaso 1: Subiendo archivos al servidor..." -ForegroundColor Yellow

$filesToUpload = @(
    "index.js",
    "add-firma-biometrica-column.sql",
    "deploy-firma-endpoints.sh",
    "test-firma-endpoints.sh"
)

foreach ($file in $filesToUpload) {
    Write-Host "  Subiendo $file..." -ForegroundColor Gray
    scp $file "${SERVER}:${REMOTE_DIR}/"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ $file subido" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Error al subir $file" -ForegroundColor Red
        exit 1
    }
}

# Paso 2: Ejecutar script de despliegue en el servidor
Write-Host "`nPaso 2: Ejecutando despliegue en el servidor..." -ForegroundColor Yellow

ssh $SERVER @"
cd $REMOTE_DIR
chmod +x deploy-firma-endpoints.sh
chmod +x test-firma-endpoints.sh
./deploy-firma-endpoints.sh
"@

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Despliegue completado exitosamente" -ForegroundColor Green
} else {
    Write-Host "`n✗ Error durante el despliegue" -ForegroundColor Red
    exit 1
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "DESPLIEGUE FINALIZADO" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "`nLos endpoints ya están disponibles en:" -ForegroundColor White
Write-Host "  https://web-intranet.mpdtucuman.gob.ar:3000/api" -ForegroundColor Cyan
