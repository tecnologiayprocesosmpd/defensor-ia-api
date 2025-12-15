# Script simple para subir archivos uno por uno
# Uso: .\upload-simple.ps1

Write-Host "=== SUBIDA SIMPLE DE ARCHIVOS ===" -ForegroundColor Cyan
Write-Host ""

# Pedir usuario
$Usuario = Read-Host "Ingresa tu usuario SSH"
$Servidor = "web-intranet.mpdtucuman.gob.ar"
$RutaDestino = "/var/www/web-intranet/defensor-ia/backend"

Write-Host ""
Write-Host "Conectando a: ${Usuario}@${Servidor}" -ForegroundColor Yellow
Write-Host "Destino: $RutaDestino" -ForegroundColor Yellow
Write-Host ""

# Verificar carpeta dist
if (-not (Test-Path "dist")) {
    Write-Host "ERROR: No existe la carpeta 'dist'" -ForegroundColor Red
    Write-Host "Ejecuta: npm run build" -ForegroundColor Yellow
    exit 1
}

Write-Host "Archivos a subir:" -ForegroundColor Green
Write-Host "1. index.js" -ForegroundColor Gray
Write-Host "2. .env" -ForegroundColor Gray
Write-Host "3. package.json" -ForegroundColor Gray
Write-Host "4. package-lock.json" -ForegroundColor Gray
Write-Host ""

$continuar = Read-Host "Continuar? (S/N)"
if ($continuar -ne "S" -and $continuar -ne "s") {
    Write-Host "Cancelado" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Subiendo archivos..." -ForegroundColor Cyan
Write-Host ""

# Subir index.js
Write-Host "[1/4] Subiendo index.js..." -ForegroundColor Cyan
scp "dist\index.js" "${Usuario}@${Servidor}:${RutaDestino}/index.js"
if ($LASTEXITCODE -eq 0) {
    Write-Host "      OK" -ForegroundColor Green
} else {
    Write-Host "      ERROR" -ForegroundColor Red
}

# Subir .env
Write-Host "[2/4] Subiendo .env..." -ForegroundColor Cyan
scp "dist\.env" "${Usuario}@${Servidor}:${RutaDestino}/.env"
if ($LASTEXITCODE -eq 0) {
    Write-Host "      OK" -ForegroundColor Green
} else {
    Write-Host "      ERROR" -ForegroundColor Red
}

# Subir package.json
Write-Host "[3/4] Subiendo package.json..." -ForegroundColor Cyan
scp "dist\package.json" "${Usuario}@${Servidor}:${RutaDestino}/package.json"
if ($LASTEXITCODE -eq 0) {
    Write-Host "      OK" -ForegroundColor Green
} else {
    Write-Host "      ERROR" -ForegroundColor Red
}

# Subir package-lock.json
Write-Host "[4/4] Subiendo package-lock.json..." -ForegroundColor Cyan
scp "dist\package-lock.json" "${Usuario}@${Servidor}:${RutaDestino}/package-lock.json"
if ($LASTEXITCODE -eq 0) {
    Write-Host "      OK" -ForegroundColor Green
} else {
    Write-Host "      ERROR" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== COMPLETADO ===" -ForegroundColor Green
Write-Host ""
Write-Host "SIGUIENTE PASO:" -ForegroundColor Yellow
Write-Host "Conectate al servidor y ejecuta:" -ForegroundColor White
Write-Host ""
Write-Host "ssh ${Usuario}@${Servidor}" -ForegroundColor Cyan
Write-Host "cd $RutaDestino" -ForegroundColor Cyan
Write-Host "npm ci --only=production" -ForegroundColor Cyan
Write-Host "pm2 restart defensor-ia-api" -ForegroundColor Cyan
Write-Host "pm2 logs defensor-ia-api --lines 50" -ForegroundColor Cyan
Write-Host ""
