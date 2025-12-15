# ✅ CHECKLIST DE DEPLOYMENT - Defensor IA API

**Fecha:** _______________  **Hora inicio:** _______  **Hora fin:** _______

**Realizado por:** _________________________________

---

## 📋 PRE-DEPLOYMENT

- [ ] Verificar archivos en `dist/` están actualizados
  ```powershell
  cd c:\Users\jnunez\Documents\Antigravity\defensor-ia-api
  npm run build
  ```

- [ ] Confirmar que `dist/index.js` tiene el endpoint GrabarActa
  ```powershell
  Select-String -Path "dist\index.js" -Pattern "GrabarActa"
  ```
  **Resultado esperado:** Línea 339 con `app.post('/api/GrabarActa'`

- [ ] Confirmar que `dist/.env` tiene el usuario correcto
  ```powershell
  Get-Content dist\.env | Select-String "DB_USER"
  ```
  **Resultado esperado:** `DB_USER=mpdlectura`

- [ ] Confirmar que `dist/.env` tiene la BD correcta
  ```powershell
  Get-Content dist\.env | Select-String "DB_NAME"
  ```
  **Resultado esperado:** `DB_NAME=Chat_DW_Ejecucion`

---

## 🔌 CONEXIÓN AL SERVIDOR

- [ ] Conectado al servidor por SSH
  ```bash
  ssh _____________@web-intranet.mpdtucuman.gob.ar
  ```
  **Usuario utilizado:** _________________________________

- [ ] Navegado al directorio correcto
  ```bash
  cd /var/www/web-intranet/defensor-ia/backend
  pwd
  ```
  **Ruta confirmada:** _________________________________

---

## 💾 BACKUP

- [ ] Backup creado con fecha/hora
  ```bash
  BACKUP_DIR="../backup_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  cp index.js .env package.json package-lock.json "$BACKUP_DIR/"
  echo "Backup en: $BACKUP_DIR"
  ```
  **Ubicación del backup:** _________________________________

---

## 📤 SUBIDA DE ARCHIVOS

**Método utilizado:** 
- [ ] Script automático (SCP)
- [ ] WinSCP/FileZilla (GUI)
- [ ] Manual (copy/paste)

### Archivos subidos:
- [ ] `index.js` (14,439 bytes, 396 líneas)
- [ ] `.env` (217 bytes, 10 líneas)
- [ ] `package.json` (854 bytes)
- [ ] `package-lock.json` (50,410 bytes)

---

## 🔍 VERIFICACIÓN DE ARCHIVOS

- [ ] Verificar endpoint GrabarActa en el servidor
  ```bash
  grep -n "GrabarActa" index.js
  ```
  **Línea encontrada:** _______

- [ ] Verificar usuario de BD
  ```bash
  cat .env | grep DB_USER
  ```
  **Usuario:** _________________________________

- [ ] Verificar nombre de BD
  ```bash
  cat .env | grep DB_NAME
  ```
  **Base de datos:** _________________________________

- [ ] Verificar número de líneas de index.js
  ```bash
  wc -l index.js
  ```
  **Líneas:** _______ (debe ser 396)

---

## 📦 INSTALACIÓN DE DEPENDENCIAS

- [ ] Dependencias instaladas
  ```bash
  npm ci --only=production
  ```
  **Errores (si los hay):** _________________________________

---

## 🔄 REINICIO DE PM2

- [ ] PM2 reiniciado
  ```bash
  pm2 restart defensor-ia-api
  ```

- [ ] Estado verificado
  ```bash
  pm2 status defensor-ia-api
  ```
  **Estado:** 
  - [ ] online
  - [ ] stopped
  - [ ] errored

- [ ] Configuración guardada
  ```bash
  pm2 save
  ```

---

## 📊 VERIFICACIÓN DE LOGS

- [ ] Logs revisados (sin errores críticos)
  ```bash
  pm2 logs defensor-ia-api --lines 50
  ```

- [ ] Mensaje de conexión exitosa a BD encontrado
  **Texto encontrado:** _________________________________

- [ ] NO aparece el usuario viejo en los logs
  - [ ] Confirmado

- [ ] Servidor ejecutándose en puerto 3000
  - [ ] Confirmado

---

## 🧪 TESTS DE FUNCIONAMIENTO

### Test 1: Health Check
```bash
curl http://localhost:3000/api/health
```
- [ ] Responde correctamente
- [ ] Status: UP
- [ ] Version: 1.0.0
- [ ] Database status: UP

### Test 2: Endpoint GrabarActa (GET - debe fallar)
```bash
curl http://localhost:3000/api/GrabarActa
```
- [ ] Responde (no timeout)
- [ ] HTTP Code: _______ (debe ser 405, NO 404)

### Test 3: Endpoint GrabarActa (POST)
```bash
curl -X POST http://localhost:3000/api/GrabarActa \
  -H "Content-Type: application/json" \
  -d '{"NroExpediente":"TEST","NroActa":"001","ContenidoActa":"Test"}'
```
- [ ] Responde (no timeout)
- [ ] HTTP Code: _______ (debe ser 200 o 500, NO 404)
- [ ] Respuesta: _________________________________

---

## 🌐 VERIFICACIÓN EXTERNA

### Desde tu PC:
```powershell
cd c:\Users\jnunez\Documents\Antigravity\defensor-ia-api
powershell -ExecutionPolicy Bypass -File test-endpoint.ps1
```

- [ ] Health check: OK
- [ ] GET /api/GrabarActa: 405 (endpoint existe)
- [ ] POST /api/GrabarActa: 200 o 500 (NO 404)

---

## 📝 VERIFICACIÓN FINAL

- [ ] El endpoint `/api/GrabarActa` NO devuelve 404
- [ ] Los logs muestran el usuario correcto (`mpdlectura`)
- [ ] La aplicación está conectada a `Chat_DW_Ejecucion`
- [ ] PM2 está en estado `online`
- [ ] No hay errores críticos en los logs
- [ ] El backup está guardado de forma segura

---

## ✅ DEPLOYMENT COMPLETADO

**Resultado:** 
- [ ] ✅ EXITOSO
- [ ] ⚠️ EXITOSO CON ADVERTENCIAS
- [ ] ❌ FALLIDO

**Notas adicionales:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

**Próximos pasos (si es necesario):**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

## 🚨 EN CASO DE PROBLEMAS

### Rollback (volver a la versión anterior):
```bash
cd /var/www/web-intranet/defensor-ia/backend
cp ../backup_YYYYMMDD_HHMMSS/* ./
pm2 restart defensor-ia-api
```

### Contactos de emergencia:
- Sistemas: _________________________________
- Responsable API: _________________________________

---

**Firma:** ___________________________  **Fecha:** _______________
