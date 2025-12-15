# Script de diagnóstico para el endpoint /api/GrabarActa

Write-Host "=== DIAGNÓSTICO DEL ENDPOINT /api/GrabarActa ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verificar health check
Write-Host "1. Verificando health check del servidor..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-WebRequest -Uri "http://web-intranet.mpdtucuman.gob.ar/api/health" -Method GET
    Write-Host "   ✓ Servidor respondiendo - Status: $($healthResponse.StatusCode)" -ForegroundColor Green
    $healthData = $healthResponse.Content | ConvertFrom-Json
    Write-Host "   - Version: $($healthData.version)" -ForegroundColor Gray
    Write-Host "   - Database Status: $($healthData.database.status)" -ForegroundColor Gray
} catch {
    Write-Host "   ✗ Error al conectar con el servidor" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 2. Verificar endpoint GrabarActa con GET (debería fallar porque es POST)
Write-Host "2. Verificando endpoint con GET (debería dar 404 o Method Not Allowed)..." -ForegroundColor Yellow
try {
    $getResponse = Invoke-WebRequest -Uri "http://web-intranet.mpdtucuman.gob.ar/api/GrabarActa" -Method GET
    Write-Host "   ⚠ GET funcionó (inesperado) - Status: $($getResponse.StatusCode)" -ForegroundColor Yellow
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 404) {
        Write-Host "   ✗ 404 Not Found - El endpoint no está registrado o hay un problema de routing" -ForegroundColor Red
    } elseif ($statusCode -eq 405) {
        Write-Host "   ✓ 405 Method Not Allowed - El endpoint existe pero no acepta GET (correcto)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠ Status Code: $statusCode" -ForegroundColor Yellow
    }
}

Write-Host ""

# 3. Verificar endpoint GrabarActa con POST
Write-Host "3. Verificando endpoint con POST..." -ForegroundColor Yellow
try {
    $body = @{
        NroExpediente = "TEST-DIAG"
        NroActa = "TEST-001"
        ContenidoActa = "Contenido de prueba para diagnóstico"
    } | ConvertTo-Json

    $postResponse = Invoke-WebRequest -Uri "http://web-intranet.mpdtucuman.gob.ar/api/GrabarActa" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body

    Write-Host "   ✓ POST exitoso - Status: $($postResponse.StatusCode)" -ForegroundColor Green
    Write-Host "   Respuesta: $($postResponse.Content)" -ForegroundColor Gray
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "   ✗ POST falló - Status Code: $statusCode" -ForegroundColor Red
    
    if ($statusCode -eq 404) {
        Write-Host "   PROBLEMA: El endpoint /api/GrabarActa no está disponible" -ForegroundColor Red
    } elseif ($statusCode -eq 500) {
        Write-Host "   PROBLEMA: Error interno del servidor (revisar logs)" -ForegroundColor Red
    }
    
    try {
        $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "   Error detallado: $($errorBody.error)" -ForegroundColor Red
    } catch {
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# 4. Listar todos los endpoints disponibles (si hay documentación)
Write-Host "4. Verificando otros endpoints conocidos..." -ForegroundColor Yellow
$endpoints = @(
    @{Path="/api/health"; Method="GET"},
    @{Path="/api/ObtenerVencimientos"; Method="GET"},
    @{Path="/api/ObtenerActas"; Method="GET"},
    @{Path="/api/InsertarObservacion"; Method="POST"}
)

foreach ($endpoint in $endpoints) {
    try {
        $testResponse = Invoke-WebRequest -Uri "http://web-intranet.mpdtucuman.gob.ar$($endpoint.Path)" -Method $endpoint.Method -TimeoutSec 5
        Write-Host "   ✓ $($endpoint.Method) $($endpoint.Path) - Status: $($testResponse.StatusCode)" -ForegroundColor Green
    } catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        if ($statusCode -eq 404) {
            Write-Host "   ✗ $($endpoint.Method) $($endpoint.Path) - 404 Not Found" -ForegroundColor Red
        } else {
            Write-Host "   ⚠ $($endpoint.Method) $($endpoint.Path) - Status: $statusCode" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "=== FIN DEL DIAGNÓSTICO ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "POSIBLES CAUSAS DEL 404:" -ForegroundColor Yellow
Write-Host "1. El servidor web (Apache/Nginx) no está redirigiendo correctamente a la API" -ForegroundColor White
Write-Host "2. PM2 no está corriendo o el proceso está caído" -ForegroundColor White
Write-Host "3. El código desplegado en producción es diferente al código local" -ForegroundColor White
Write-Host "4. Hay un problema con el proxy reverso o la configuración de rutas" -ForegroundColor White
Write-Host ""
Write-Host "PRÓXIMOS PASOS:" -ForegroundColor Yellow
Write-Host "1. Verificar logs del servidor: pm2 logs defensor-ia-api" -ForegroundColor White
Write-Host "2. Verificar estado de PM2: pm2 status" -ForegroundColor White
Write-Host "3. Revisar configuración de Apache/Nginx para el proxy reverso" -ForegroundColor White
Write-Host "4. Verificar que el código esté actualizado en producción" -ForegroundColor White
