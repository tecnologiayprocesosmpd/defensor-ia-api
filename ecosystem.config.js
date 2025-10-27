module.exports = {
  apps: [
    {
      // Nombre del proceso en PM2
      name: process.env.PM2_APP_NAME || 'defensor-ia-api',

      // Script de entrada
      script: process.env.PM2_SCRIPT || 'index.js',

      // Directorio de trabajo (carpeta donde está index.js y package.json)
      cwd: process.env.PM2_CWD || '/var/www/web-intranet/defensor-ia/backend',

      // Modo de ejecución e instancias
      exec_mode: process.env.PM2_EXEC_MODE || 'fork',
      instances: parseInt(process.env.PM2_INSTANCES || '1', 10),

      // Comportamiento de reinicio/observación
      watch: (process.env.PM2_WATCH || 'false') === 'true',
      autorestart: (process.env.PM2_AUTORESTART || 'true') === 'true',
      max_restarts: parseInt(process.env.PM2_MAX_RESTARTS || '10', 10),
      max_memory_restart: process.env.PM2_MAX_MEMORY || '256M',

      // Variables de entorno para la app
      env: {
        NODE_ENV: process.env.NODE_ENV || 'production',
        PORT: parseInt(process.env.PORT || '3000', 10)
      },

      // Logs (si no se setean, PM2 usa los defaults por usuario)
      error_file: process.env.PM2_ERROR_LOG,
      out_file: process.env.PM2_OUT_LOG,
      time: true
    }
  ]
};