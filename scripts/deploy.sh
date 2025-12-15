#!/usr/bin/env bash
set -euo pipefail

# ==== Configuración parametrizable ====
# Puedes sobreescribir estas variables al invocar el script:
#   APP_NAME="otro-nombre" APP_DIR="/ruta/a/app" PORT=4000 ./deploy.sh
APP_NAME="${APP_NAME:-defensor-ia-api}"
APP_DIR="${APP_DIR:-/var/www/web-intranet/defensor-ia/backend}"
PM2_CONFIG="${PM2_CONFIG:-$APP_DIR/ecosystem.config.js}"
# Si exportas PORT aquí, PM2 lo tomará cuando cargue el ecosystem.config.js
PORT="${PORT:-3000}"
export PORT

PM2_APP_NAME_ENV="${PM2_APP_NAME:-$APP_NAME}"
PM2_CWD_ENV="${PM2_CWD:-$APP_DIR}"
PM2_SCRIPT_ENV="${PM2_SCRIPT:-index.js}"
PM2_INSTANCES_ENV="${PM2_INSTANCES:-1}"
PM2_EXEC_MODE_ENV="${PM2_EXEC_MODE:-fork}"

echo "[deploy] Despliegue de $APP_NAME iniciando..."
echo "[deploy] Directorio de la app: $APP_DIR"
echo "[deploy] Puerto: $PORT"

if [[ ! -d "$APP_DIR" ]]; then
  echo "[deploy][ERROR] No existe el directorio $APP_DIR"
  exit 1
fi

cd "$APP_DIR"

echo "[deploy] Node: $(node -v || echo 'no encontrado')"
echo "[deploy] NPM:  $(npm -v || echo 'no encontrado')"
echo "[deploy] PM2:  $(pm2 -v || echo 'no encontrado')"

if [[ ! -f package.json ]]; then
  echo "[deploy][ERROR] No se encuentra package.json en $APP_DIR"
  exit 1
fi

echo "[deploy] Instalando dependencias de producción..."
if [[ -f package-lock.json ]]; then
  npm ci --only=production
else
  npm install --production
fi

echo "[deploy] Reiniciando con PM2..."
if [[ -f "$PM2_CONFIG" ]]; then
  # Preferir iniciar usando el ecosystem para asegurar cwd/env/logs
  if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
    PM2_APP_NAME="$PM2_APP_NAME_ENV" PM2_CWD="$PM2_CWD_ENV" PM2_SCRIPT="$PM2_SCRIPT_ENV" PM2_INSTANCES="$PM2_INSTANCES_ENV" PM2_EXEC_MODE="$PM2_EXEC_MODE_ENV" \
      pm2 reload "$PM2_CONFIG" --only "$APP_NAME" --env production || pm2 restart "$APP_NAME"
  else
    PM2_APP_NAME="$PM2_APP_NAME_ENV" PM2_CWD="$PM2_CWD_ENV" PM2_SCRIPT="$PM2_SCRIPT_ENV" PM2_INSTANCES="$PM2_INSTANCES_ENV" PM2_EXEC_MODE="$PM2_EXEC_MODE_ENV" \
      pm2 start "$PM2_CONFIG" --only "$APP_NAME" --env production
  fi
else
  # Fallback si no hay ecosystem: reiniciar por nombre o iniciar con parámetros básicos
  if pm2 describe "$APP_NAME" >/dev/null 2>&1; then
    pm2 restart "$APP_NAME"
  else
    pm2 start "$PM2_SCRIPT_ENV" --name "$APP_NAME" --cwd "$APP_DIR"
  fi
fi

pm2 save || true
pm2 status "$APP_NAME"

echo "[deploy] Verificando healthcheck local..."
set +e
curl -fsS "http://127.0.0.1:${PORT}/health" >/dev/null && OK1=1 || OK1=0
curl -fsS "http://127.0.0.1:${PORT}/api/health" >/dev/null && OK2=1 || OK2=0
set -e

if [[ "$OK1" == "1" || "$OK2" == "1" ]]; then
  echo "[deploy] Healthcheck OK (alguna ruta respondió)"
else
  echo "[deploy][WARN] No respondió /health ni /api/health en 127.0.0.1:${PORT_ENV}"
  echo "           Revisa logs con: pm2 logs ${APP_NAME} --lines 200"
fi

echo "[deploy] Despliegue finalizado."