# Script para subir archivos al servidor
# Uso: .\upload-to-server.ps1 -Usuario "tu_usuario"

param(
    [Parameter(Mandatory=$true)]
    [string]$Usuario,
    
    [string]$Servidor = "web-intranet.mpdtucuman.gob.ar",
    [string]$RutaDestino = "/var/www/web-intranet/defensor-ia/backend"
)

Write-Host "=== SUBIDA DE ARCHIVOS AL SERVIDOR ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Servidor: $Servidor" -ForegroundColor Yellow
Write-Host "Usuario: $Usuario" -ForegroundColor Yellow
Write-Host "Destino: $RutaDestino" -ForegroundColor Yellow
Write-Host ""

# Verificar que existe la carpeta dist
if (-not (Test-Path "dist")) {
    Write-Host "ERROR: No existe la carpeta 'dist'. Ejecuta 'npm run build' primero." -ForegroundColor Red
    exit 1
}

# Verificar que existen los archivos necesarios
$archivos = @("index.js", ".env", "package.json", "package-lock.json")
$archivosFaltantes = @()

foreach ($archivo in $archivos) {
    if (-not (Test-Path "dist\$archivo")) {
        $archivosFaltantes += $archivo
    }
}

if ($archivosFaltantes.Count -gt 0) {
    Write-Host "ERROR: Faltan archivos en dist/:" -ForegroundColor Red
    $archivosFaltantes | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

Write-Host "Archivos a subir:" -ForegroundColor Green
$archivos | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
Write-Host ""

# Preguntar confirmacion
$confirmacion = Read-Host "Deseas continuar con la subida? (S/N)"
if ($confirmacion -ne "S" -and $confirmacion -ne "s") {
    Write-Host "Operacion cancelada." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Subiendo archivos..." -ForegroundColor Yellow
Write-Host ""

# Subir cada archivo
$exitosos = 0
$fallidos = 0

foreach ($archivo in $archivos) {
    Write-Host "Subiendo $archivo..." -ForegroundColor Cyan
    
    try {
        # Usar scp para subir el archivo
        $scpDestino = "${Usuario}@${Servidor}:${RutaDestino}/${archivo}"
        
        # Ejecutar scp
        scp "dist\$archivo" $scpDestino
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  OK - $archivo subido correctamente" -ForegroundColor Green
            $exitosos++
        } else {
            Write-Host "  ERROR - Fallo la subida de $archivo" -ForegroundColor Red
            $fallidos++
        }
    } catch {
        Write-Host "  ERROR - $($_.Exception.Message)" -ForegroundColor Red
        $fallidos++
    }
    
    Write-Host ""
}

# Resumen
Write-Host "=== RESUMEN ===" -ForegroundColor Cyan
Write-Host "Exitosos: $exitosos" -ForegroundColor Green
if ($fallidos -gt 0) {
    Write-Host "Fallidos: $fallidos" -ForegroundColor Red
} else {
    Write-Host "Fallidos: $fallidos" -ForegroundColor Gray
}
Write-Host ""

if ($fallidos -eq 0) {
    Write-Host "Todos los archivos se subieron correctamente!" -ForegroundColor Green
    Write-Host ""
    Write-Host "PROXIMOS PASOS:" -ForegroundColor Yellow
    Write-Host "1. Conectarte al servidor por SSH:" -ForegroundColor White
    Write-Host "   ssh ${Usuario}@${Servidor}" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Verificar los archivos:" -ForegroundColor White
    Write-Host "   cd $RutaDestino" -ForegroundColor Gray
    Write-Host "   grep -n 'GrabarActa' index.js" -ForegroundColor Gray
    Write-Host "   cat .env | grep DB_USER" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Reinstalar dependencias y reiniciar PM2:" -ForegroundColor White
    Write-Host "   npm ci --only=production" -ForegroundColor Gray
    Write-Host "   pm2 restart defensor-ia-api" -ForegroundColor Gray
    Write-Host "   pm2 logs defensor-ia-api --lines 50" -ForegroundColor Gray
} else {
    Write-Host "Hubo errores al subir algunos archivos. Revisa los mensajes arriba." -ForegroundColor Red
    Write-Host ""
    Write-Host "ALTERNATIVAS:" -ForegroundColor Yellow
    Write-Host "1. Usar WinSCP o FileZilla (interfaz grafica)" -ForegroundColor White
    Write-Host "2. Copiar y pegar manualmente el contenido de los archivos" -ForegroundColor White
    Write-Host "3. Verificar que tienes acceso SSH al servidor" -ForegroundColor White
}
