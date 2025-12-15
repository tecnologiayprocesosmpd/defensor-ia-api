# Scripts de Prueba para Endpoints de Firmas Biométricas

## Preparación
```powershell
# Variables de configuración
$API_URL = "https://web-intranet.mpdtucuman.gob.ar:3000/api"
# O para pruebas locales:
# $API_URL = "http://localhost:3000/api"
```

## Test 1: Insertar acta con firma biométrica
```powershell
$body = @{
    NroExpediente = "TEST-12345/2024"
    NroActa = "ENT-TEST001"
    ContenidoActa = "<html><body>Acta de prueba con firma biométrica</body></html>"
    FirmaID = "a3f5e9c7b2d1f8e4c6a9b3d7f1e5c8a2b4d6f0e3c7a1b5d9f2e6c0a4b8d3f7e1"
    FirmaBiometrica = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
} | ConvertTo-Json

Invoke-RestMethod -Uri "$API_URL/GrabarActa" -Method Post -Body $body -ContentType "application/json"
```

## Test 2: Obtener todas las actas (con firmas)
```powershell
Invoke-RestMethod -Uri "$API_URL/ObtenerActas" -Method Get | ConvertTo-Json -Depth 3
```

## Test 3: Obtener acta específica por ID
```powershell
# Reemplazar 123 con un ActaId real
$actaId = 123
Invoke-RestMethod -Uri "$API_URL/ObtenerActa/$actaId" -Method Get | ConvertTo-Json -Depth 3
```

## Test 4: Obtener actas por número de expediente
```powershell
$nroExpediente = "TEST-12345/2024"
$nroExpedienteEncoded = [System.Web.HttpUtility]::UrlEncode($nroExpediente)
Invoke-RestMethod -Uri "$API_URL/ObtenerActasPorExpediente/$nroExpedienteEncoded" -Method Get | ConvertTo-Json -Depth 3
```

## Test 5: Acta no encontrada (404)
```powershell
try {
    Invoke-RestMethod -Uri "$API_URL/ObtenerActa/999999" -Method Get
} catch {
    Write-Host "Error esperado (404):" $_.Exception.Message -ForegroundColor Yellow
}
```

## Test 6: Actualizar acta existente con firma
```powershell
$body = @{
    ActaId = 123  # Reemplazar con un ID real
    NroExpediente = "TEST-12345/2024"
    NroActa = "ENT-TEST001-UPD"
    ContenidoActa = "<html><body>Acta ACTUALIZADA con firma</body></html>"
    FirmaID = "b4g6f0d8c3e2g9f5d7b0e4g8c2f6b9d3g7e1c5g9f3e7c1g5d9f3e7b1g5d9f3e7c1"
    FirmaBiometrica = "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=="
} | ConvertTo-Json

Invoke-RestMethod -Uri "$API_URL/GrabarActa" -Method Post -Body $body -ContentType "application/json"
```
