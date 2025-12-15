#!/bin/bash
# Scripts de prueba para endpoints de firmas biométricas (Bash)

API_URL="http://localhost:3000/api"

echo "=== TEST 1: Insertar acta con firma biométrica ==="
curl -X POST $API_URL/GrabarActa \
  -H "Content-Type: application/json" \
  -d '{
    "NroExpediente": "TEST-12345/2024",
    "NroActa": "ENT-TEST001",
    "ContenidoActa": "<html><body>Acta de prueba con firma biométrica</body></html>",
    "FirmaID": "a3f5e9c7b2d1f8e4c6a9b3d7f1e5c8a2b4d6f0e3c7a1b5d9f2e6c0a4b8d3f7e1",
    "FirmaBiometrica": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
  }'

echo -e "\n\n=== TEST 2: Obtener todas las actas ==="
curl $API_URL/ObtenerActas | jq

echo -e "\n\n=== TEST 3: Obtener acta por ID (reemplazar 123 con ID real) ==="
curl $API_URL/ObtenerActa/123 | jq

echo -e "\n\n=== TEST 4: Obtener actas por expediente ==="
curl "$API_URL/ObtenerActasPorExpediente/TEST-12345%2F2024" | jq

echo -e "\n\n=== TEST 5: Acta no encontrada (404) ==="
curl -i $API_URL/ObtenerActa/999999

echo -e "\n\n=== TEST 6: Actualizar acta con firma (reemplazar ActaId con ID real) ==="
curl -X POST $API_URL/GrabarActa \
  -H "Content-Type: application/json" \
  -d '{
    "ActaId": 123,
    "NroExpediente": "TEST-12345/2024",
    "NroActa": "ENT-TEST001-UPD",
    "ContenidoActa": "<html><body>Acta ACTUALIZADA con firma</body></html>",
    "FirmaID": "b4g6f0d8c3e2g9f5d7b0e4g8c2f6b9d3g7e1c5g9f3e7c1g5d9f3e7b1g5d9f3e7c1",
    "FirmaBiometrica": "iVBORw0KGgoAAAANSUhEUgAAAAUAAAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO9TXL0Y4OHwAAAABJRU5ErkJggg=="
  }' | jq
