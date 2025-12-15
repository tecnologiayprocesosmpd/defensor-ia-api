# Test HTTPS del endpoint GrabarActa

Write-Host "=== TEST HTTPS DEL ENDPOINT ===" -ForegroundColor Cyan
Write-Host ""

# Ignorar errores de certificado SSL (si es necesario)
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

# Test POST  
Write-Host "Test POST /api/GrabarActa..." -ForegroundColor Yellow

try {
    $body = @{
        NroExpediente = "TEST-123"
        NroActa = "001"
        ContenidoActa = "Contenido de prueba"
    } | ConvertTo-Json
    
    $response = Invoke-WebRequest `
        -Uri "https://web-intranet.mpdtucuman.gob.ar/api/GrabarActa" `
        -Method POST `
        -ContentType "application/json" `
        -Body $body `
        -UseBasicParsing
    
    Write-Host "SUCCESS - HTTP $($response.StatusCode)" -ForegroundColor Green
    Write-Host "Response: $($response.Content)" -ForegroundColor Gray
    
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    Write-Host "HTTP Status: $statusCode" -ForegroundColor $(if ($statusCode -eq 404) { "Red" } elseif ($statusCode -eq 500) { "Yellow" } else { "Cyan" })
    
    if ($_.ErrorDetails.Message) {
        Write-Host "Response: $($_.ErrorDetails.Message)" -ForegroundColor Gray
    }
    
    if ($statusCode -eq 404) {
        Write-Host "" -ForegroundColor Red
        Write-Host "ERROR: El endpoint NO EXISTE (404)" -ForegroundColor Red
        Write-Host "Verifica en el servidor que Nginx este configurado correctamente" -ForegroundColor Yellow
    } elseif ($statusCode -eq 500) {
        Write-Host "" -ForegroundColor Yellow
        Write-Host "OK: El endpoint EXISTE y responde (500 = error de validacion esperado)" -ForegroundColor Green
    } elseif ($statusCode -eq 200) {
        Write-Host "" -ForegroundColor Green
        Write-Host "EXITO TOTAL: El endpoint funciona perfectamente!" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "=== FIN DEL TEST ===" -ForegroundColor Cyan
