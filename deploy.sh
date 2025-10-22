#!/bin/bash

echo "📤 Subiendo backend al servidor..."
rsync -avz --delete --exclude='node_modules' --exclude='.git' ./ adminmpd@web-intranet.mpdtucuman.gob.ar:/var/www/web-intranet/defensor-ia/backend/

echo "🔄 Instalando dependencias y reiniciando con PM2..."
ssh adminmpd@web-intranet.mpdtucuman.gob.ar "cd /var/www/web-intranet/defensor-ia/backend && npm install && pm2 restart defensor-ia-api"

echo "✅ Backend actualizado en web-intranet.mpdtucuman.gob.ar"