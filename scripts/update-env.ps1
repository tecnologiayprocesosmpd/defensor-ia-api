# Script para actualizar solo el .env en el servidor
# Uso: .\update-env.ps1

Write-Host "=== ACTUALIZACION DE .ENV EN EL SERVIDOR ===" -ForegroundColor Cyan
Write-Host ""

# Pedir usuario
$Usuario = Read-Host "Ingresa tu usuario SSH"
$Servidor = "web-intranet.mpdtucuman.gob.ar"
$RutaDestino = "/var/www/web-intranet/defensor-ia/backend"

Write-Host ""
Write-Host "Paso 1: Reconstruyendo dist..." -ForegroundColor Yellow
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Fallo npm run build" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Paso 2: Verificando nuevo .env..." -ForegroundColor Yellow
if (-not (Test-Path "dist\.env")) {
    Write-Host "ERROR: No existe dist\.env" -ForegroundColor Red
    exit 1
}

Write-Host "Contenido del nuevo .env:" -ForegroundColor Cyan
Get-Content "dist\.env" | ForEach-Object {
    if ($_ -match "PASSWORD") {
        Write-Host "  $_" -ForegroundColor Gray
    } else {
        Write-Host "  $_" -ForegroundColor White
    }
}
Write-Host ""

$usuarioDB = (Get-Content "dist\.env" | Select-String "DB_USER=").ToString().Split("=")[1]
Write-Host "Usuario de BD: $usuarioDB" -ForegroundColor Green
Write-Host ""

$continuar = Read-Host "Subir este .env al servidor? (S/N)"
if ($continuar -ne "S" -and $continuar -ne "s") {
    Write-Host "Cancelado" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Paso 3: Subiendo .env al servidor..." -ForegroundColor Yellow
scp "dist\.env" "${Usuario}@${Servidor}:${RutaDestino}/.env"

if ($LASTEXITCODE -eq 0) {
    Write-Host "OK - .env subido correctamente" -ForegroundColor Green
} else {
    Write-Host "ERROR - Fallo la subida" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== COMPLETADO ===" -ForegroundColor Green
Write-Host ""
Write-Host "SIGUIENTE PASO (ejecutar en el servidor):" -ForegroundColor Yellow
Write-Host ""
Write-Host "ssh ${Usuario}@${Servidor}" -ForegroundColor Cyan
Write-Host "cd ${RutaDestino}" -ForegroundColor Cyan
Write-Host "cat .env | grep DB_USER  # Verificar usuario" -ForegroundColor Cyan
Write-Host "pm2 restart defensor-ia-api  # IMPORTANTE: Reiniciar PM2" -ForegroundColor Cyan
Write-Host "pm2 logs defensor-ia-api --lines 50  # Ver logs" -ForegroundColor Cyan
Write-Host ""
Write-Host "IMPORTANTE: Debes reiniciar PM2 para que cargue el nuevo .env!" -ForegroundColor Red
Write-Host ""
