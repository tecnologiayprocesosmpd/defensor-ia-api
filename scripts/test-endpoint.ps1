# Test simple del endpoint GrabarActa

Write-Host "=== Test del endpoint /api/GrabarActa ===" -ForegroundColor Cyan

# Test 1: Health check
Write-Host "`n1. Health check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "https://web-intranet.mpdtucuman.gob.ar/api/health" -Method GET
    Write-Host "OK - Version: $($health.version)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: GET en GrabarActa (deberia dar 404 o 405)
Write-Host "`n2. GET /api/GrabarActa (deberia fallar)..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://web-intranet.mpdtucuman.gob.ar/api/GrabarActa" -Method GET
    Write-Host "Inesperado - Status: $($response.StatusCode)" -ForegroundColor Yellow
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 404) {
        Write-Host "404 Not Found - EL ENDPOINT NO EXISTE" -ForegroundColor Red
    } elseif ($code -eq 405) {
        Write-Host "405 Method Not Allowed - El endpoint existe" -ForegroundColor Green
    } else {
        Write-Host "Status: $code" -ForegroundColor Yellow
    }
}

# Test 3: POST en GrabarActa
Write-Host "`n3. POST /api/GrabarActa..." -ForegroundColor Yellow
try {
    $body = @{
        NroExpediente = "TEST"
        NroActa = "001"
        ContenidoActa = "Test"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "https://web-intranet.mpdtucuman.gob.ar/api/GrabarActa" -Method POST -ContentType "application/json" -Body $body
    Write-Host "OK - $($response.mensaje)" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    Write-Host "ERROR - Status: $code" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "Detalles: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
}

Write-Host "`n=== Fin del test ===" -ForegroundColor Cyan
