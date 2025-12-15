const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '10mb' })); // Aumentar límite para firmas biométricas

// Configuración de la conexión a PostgreSQL
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  schema: process.env.DB_SCHEMA
});

// Configurar el cliente pg para confiar en la conexión
process.env.PGSSLMODE = 'disable';

// Variables globales para el estado de la aplicación
const startTime = new Date();
let dbStatus = {
  isConnected: false,
  lastCheck: null,
  error: null
};

// Función para verificar la conexión a la base de datos
async function checkDatabaseConnection() {
  try {
    const client = await pool.connect();
    await client.query('SELECT 1');
    client.release();
    dbStatus = {
      isConnected: true,
      lastCheck: new Date(),
      error: null
    };
    return true;
  } catch (error) {
    dbStatus = {
      isConnected: false,
      lastCheck: new Date(),
      error: error.message
    };
    console.error('Error al verificar la conexión a la base de datos:', error);
    return false;
  }
}

pool.on('error', (err) => {
  console.error('Error inesperado en el pool de conexiones:', err);
});

// Verificar conexión a la base de datos
pool.connect((err, client, done) => {
  if (err) {
    console.error('Error al conectar con la base de datos:', err);
    dbStatus.isConnected = false;
    dbStatus.error = err.message;
  } else {
    console.log('Conexión exitosa a la base de datos');
    dbStatus.isConnected = true;
    done();
  }
  dbStatus.lastCheck = new Date();
});

// GET - Health check
app.get(['/api/health', '/health'], async (req, res) => {
  try {
    // Verificar la conexión a la base de datos en tiempo real
    await checkDatabaseConnection();

    // Calcular tiempo de actividad
    const uptime = new Date() - startTime;
    const uptimeFormatted = {
      days: Math.floor(uptime / (1000 * 60 * 60 * 24)),
      hours: Math.floor((uptime % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
      minutes: Math.floor((uptime % (1000 * 60 * 60)) / (1000 * 60)),
      seconds: Math.floor((uptime % (1000 * 60)) / 1000)
    };

    // Obtener información del package.json
    const packageInfo = require('./package.json');

    // Construir respuesta
    const healthStatus = {
      status: 'UP',
      version: packageInfo.version,
      name: packageInfo.name,
      uptime: uptimeFormatted,
      timestamp: new Date(),
      database: {
        status: dbStatus.isConnected ? 'UP' : 'DOWN',
        lastCheck: dbStatus.lastCheck,
        error: dbStatus.error
      },
      environment: process.env.NODE_ENV || 'development'
    };

    // Enviar respuesta con código 200 si todo está bien, o 503 si hay problemas con la BD
    const statusCode = dbStatus.isConnected ? 200 : 503;
    res.status(statusCode).json(healthStatus);
  } catch (error) {
    console.error('Error al verificar el estado de la API:', error);
    res.status(500).json({
      status: 'ERROR',
      error: 'Error al verificar el estado de la API',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET - Obtener vencimientos
app.get('/api/ObtenerVencimientos', async (req, res) => {
  try {
    // Filtros dinámicos
    const params = [];
    const filters = [];

    // Soporte para múltiples pares de Centro/Oficina vía query param JSON 'pairs'
    // Ejemplo: pairs=[{"OficinaSistCarcelarioCentro":"Capital","OficinaSistCarcelarioOficina":"DEFENSORIA OFICIAL PENAL III NOM."},{"OficinaSistCarcelarioCentro":"Capital","OficinaSistCarcelarioOficina":"DEFENSORIA OFICIAL PENAL DE LA XI NOM"}]
    let pairs = [];
    const pairsRaw = req.query.pairs || req.query.Pairs;
    if (pairsRaw) {
      try {
        const parsed = typeof pairsRaw === 'string' ? JSON.parse(pairsRaw) : pairsRaw;
        if (Array.isArray(parsed)) {
          pairs = parsed;
        } else if (parsed && typeof parsed === 'object') {
          pairs = [parsed];
        }
      } catch (e) {
        // Ignorar error de parseo; se tratarán filtros individuales si están presentes
      }
    }

    if (pairs.length > 0) {
      const pairConditions = [];
      for (const item of pairs) {
        const cj = item.OficinaSistCarcelarioCentro || item.CentroJudicial || item.centrojudicial;
        const of = item.OficinaSistCarcelarioOficina || item.Oficina || item.oficina;
        if (cj && of) {
          params.push(cj);
          const cjIdx = params.length;
          params.push(of);
          const ofIdx = params.length;
          pairConditions.push(`(translate(LOWER(vb.centrojudicial), 'áéíóúü', 'aeiouu') = translate(LOWER($${cjIdx}), 'áéíóúü', 'aeiouu') AND translate(LOWER(vb.oficina), 'áéíóúü', 'aeiouu') = translate(LOWER($${ofIdx}), 'áéíóúü', 'aeiouu'))`);
        }
      }
      if (pairConditions.length > 0) {
        filters.push(`(${pairConditions.join(' OR ')})`);
      }
    } else {
      // Parámetros opcionales individuales (acepta mayúsculas/minúsculas)
      const CentroJudicial = req.query.CentroJudicial || req.query.centrojudicial;
      const Oficina = req.query.Oficina || req.query.oficina;
      if (CentroJudicial) {
        params.push(CentroJudicial);
        filters.push(`translate(LOWER(vb.centrojudicial), 'áéíóúü', 'aeiouu') = translate(LOWER($${params.length}), 'áéíóúü', 'aeiouu')`);
      }
      if (Oficina) {
        params.push(Oficina);
        filters.push(`translate(LOWER(vb.oficina), 'áéíóúü', 'aeiouu') = translate(LOWER($${params.length}), 'áéíóúü', 'aeiouu')`);
      }
    }

    const query = `
      SELECT 
        vb.centrojudicial as "CentroJudicial",
        vb.sistema as "Sistema",
        vb.oficina as "Oficina",
        vb.expt as "Expediente",
        vb.persona as "Persona",
        vb.documento as "Documento",
        vb.caracterparte as "CaracterParte",
        vb.grupo as "Grupo",
        vb.alojamiento as "Alojamiento",
        vb.pena as "Pena",
        vb.delito as "Delito",
        vb.cumpl_1_2_de_condena as "Cumpl12deCondena",
        vb.cumpl_2_3_de_condena as "Cumpl23deCondena",
        vb.cumpl_6_meses as "Cumpl6Meses",
        vb.cumpl_3_meses as "Cumpl3Meses",
        vb.cumplimiento_condena as "CumplimientoCondena",
        vb.responsable as "VencimientosBenefResp",
        vb.expt_fisc as "ExpedienteFisc",
        vb.estado as "VencimientosBenefEstado",
        vbo.observaciones as "observaciones",
        vbo.fecha as "fecha",
        vb.procid as "procid",
        vb.partid as "partid",
        vb.cumpl_1_2_de_condena_esta as "cumpl_1_2_de_condena_esta",
        vb.cumpl_2_3_de_condena_esta as "cumpl_2_3_de_condena_esta",
        vb.cumpl_6_meses_esta as "cumpl_6_meses_esta",
        vb.cumpl_3_meses_esta as "cumpl_3_meses_esta",
        vb.cumpl_condena_esta as "cumpl_condena_esta",
        vb.ultima_visita as "ultima_visita",
        vb.fecha_hecho as "fecha_hecho",
        vb.en_dis_tra as "en_dis_tra",
        vb.texto as "texto",
        vb.caratula as "caratula"
      FROM public.vencimientos_beneficios vb
      LEFT JOIN vencimientos_beneficios_obs vbo ON
        vb.procid = vbo.vencimientos_beneficios_obspro AND
        vb.partid = vbo.vencimientos_beneficios_obspar
      WHERE vb.responsable IS NOT NULL
        AND vb.oficina IN (
          'DEFENSORIA OFICIAL PENAL DE LA X NOM',
          'DEFENSORIA OFICIAL PENAL DE LA XI NOM',
          'MPD - EQUIPO OPERATIVO DE EJECUCION',
          'MPD - EQUIPO OPERATIVO N 6 - EJECUCION',
          'DEFENSORIA OFICIAL PENAL III NOM.'
        )
        AND vb.caracterparte IN (
          'CONDENADO - CON PERPETUA',
          'CONDENADO/A -  PRISION DOMICILIARIA CON DISPOSITIVO ELECTRONICO',
          'CONDENADO/A - CON BENEFICIO',
          'CONDENADO/A - CON BENEFICIO - LIBERTAD CONDICIONAL',
          'CONDENADO/A - CON BENEFICIO - SALIDAS TRANSITORIAS',
          'CONDENADO/A - CON BENEFICIO - SEMILIBERTAD',
          'CONDENADO/A - CON INTERNACION',
          'CONDENADO/A - CON LIBERTAD VIGILADA',
          'CONDENADO/A - PRESO/A',
          'CONDENADO/A - PRISION DOMICILIARIA',
          'CONDENADO/A - PRISION DOMICILIARIA CON DISPOSITIVO ELECTRONICO'
        )
        ${filters.length ? ' AND ' + filters.join(' AND ') : ''}
    `;

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener vencimientos:', error);
    const errorMessage = error.code === '28P01' ? 'Error de autenticación con la base de datos' :
      error.code === '3D000' ? 'Base de datos no encontrada' :
        error.code === 'ECONNREFUSED' ? 'No se puede conectar al servidor de base de datos' :
          error.code === '42P01' ? 'Tabla no encontrada' :
            'Error interno del servidor';
    res.status(500).json({
      error: errorMessage,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST - Insertar o actualizar observación
app.post('/api/InsertarObservacion', async (req, res) => {
  try {
    const { obspro, obspar, obscen, obsexp, observaciones, fecha } = req.body;

    // Verificar si el registro ya existe
    const checkQuery = `
      SELECT * FROM vencimientos_beneficios_obs 
      WHERE vencimientos_beneficios_obspro = $1 
      AND vencimientos_beneficios_obs par = $2
    `;

    const checkResult = await pool.query(checkQuery, [obspro, obspar]);

    let mensaje = '';

    if (checkResult.rows.length > 0) {
      // Si existe, actualizar
      const updateQuery = `
        UPDATE vencimientos_beneficios_obs 
        SET vencimientos_beneficios_obscen = $3,
            vencimientos_beneficios_obsexp = $4,
            observaciones = $5,
            fecha = COALESCE($6, NOW())
        WHERE vencimientos_beneficios_obspro = $1 
        AND vencimientos_beneficios_obspar = $2
      `;

      await pool.query(updateQuery, [obspro, obspar, obscen, obsexp, observaciones, fecha]);
      mensaje = 'Observación actualizada correctamente';
    } else {
      // Si no existe, insertar
      const insertQuery = `
        INSERT INTO vencimientos_beneficios_obs (
          vencimientos_beneficios_obspro,
          vencimientos_beneficios_obspar,
          vencimientos_beneficios_obscen,
          vencimientos_beneficios_obsexp,
          observaciones,
          fecha
        ) VALUES ($1, $2, $3, $4, $5, COALESCE($6, NOW()))
      `;

      await pool.query(insertQuery, [obspro, obspar, obscen, obsexp, observaciones, fecha]);
      mensaje = 'Observación insertada correctamente';
    }

    res.json({ mensaje });
  } catch (error) {
    console.error('Error al insertar/actualizar observación:', error);
    const errorMessage = error.code === '23502' ? 'Faltan campos requeridos' :
      error.code === '42P01' ? 'Tabla no encontrada' :
        'Error interno del servidor';
    res.status(500).json({
      error: errorMessage,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET - Obtener datos de la tabla actas
app.get('/api/ObtenerActas', async (req, res) => {
  try {
    const query = `
      SELECT 
        "ActaId",
        "Nro de expediente",
        "Nro de acta",
        "Contenido del Acta",
        "FirmaID",
        "FirmaBiometrica"
      FROM public.actas
      ORDER BY "ActaId" DESC
    `;

    const result = await pool.query(query);
    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener actas:', error);
    const errorMessage = error.code === '42P01' ? 'Tabla no encontrada' :
      'Error interno del servidor';
    res.status(500).json({
      error: errorMessage,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET - Obtener un acta específica por ID
app.get('/api/ObtenerActa/:actaId', async (req, res) => {
  try {
    const { actaId } = req.params;

    const query = `
      SELECT 
        "ActaId",
        "Nro de expediente",
        "Nro de acta",
        "Contenido del Acta",
        "FirmaID",
        "FirmaBiometrica"
      FROM public.actas
      WHERE "ActaId" = $1
    `;

    const result = await pool.query(query, [actaId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Acta no encontrada' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener acta:', error);
    const errorMessage = error.code === '42P01' ? 'Tabla no encontrada' :
      error.code === '22P02' ? 'ID de acta inválido' :
        'Error interno del servidor';
    res.status(500).json({
      error: errorMessage,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// GET - Obtener actas por número de expediente
app.get('/api/ObtenerActasPorExpediente/:nroExpediente', async (req, res) => {
  try {
    const { nroExpediente } = req.params;

    const query = `
      SELECT 
        "ActaId",
        "Nro de expediente",
        "Nro de acta",
        "Contenido del Acta",
        "FirmaID",
        "FirmaBiometrica"
      FROM public.actas
      WHERE "Nro de expediente" = $1
      ORDER BY "ActaId" DESC
    `;

    const result = await pool.query(query, [nroExpediente]);
    res.json(result.rows);
  } catch (error) {
    console.error('Error al obtener actas por expediente:', error);
    const errorMessage = error.code === '42P01' ? 'Tabla no encontrada' :
      'Error interno del servidor';
    res.status(500).json({
      error: errorMessage,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// POST - Insertar o actualizar acta
app.post('/api/GrabarActa', async (req, res) => {
  try {
    const { ActaId, NroExpediente, NroActa, ContenidoActa, FirmaID, FirmaBiometrica } = req.body;

    let mensaje = '';

    if (ActaId) {
      // Si viene el ID, actualizar el registro existente
      const updateQuery = `
        UPDATE public.actas 
        SET "Nro de expediente" = $2,
            "Nro de acta" = $3,
            "Contenido del Acta" = $4,
            "FirmaID" = $5,
            "FirmaBiometrica" = $6
        WHERE "ActaId" = $1
        RETURNING "ActaId"
      `;

      const result = await pool.query(updateQuery, [ActaId, NroExpediente, NroActa, ContenidoActa, FirmaID, FirmaBiometrica]);

      if (result.rowCount > 0) {
        mensaje = 'Acta actualizada correctamente';
      } else {
        return res.status(404).json({ error: 'Acta no encontrada' });
      }
    } else {
      // Si no viene el ID, insertar un nuevo registro
      const insertQuery = `
        INSERT INTO public.actas (
          "Nro de expediente",
          "Nro de acta",
          "Contenido del Acta",
          "FirmaID",
          "FirmaBiometrica"
        ) VALUES ($1, $2, $3, $4, $5)
        RETURNING "ActaId"
      `;

      const result = await pool.query(insertQuery, [NroExpediente, NroActa, ContenidoActa, FirmaID, FirmaBiometrica]);
      mensaje = 'Acta insertada correctamente';
    }

    res.json({ mensaje });
  } catch (error) {
    console.error('Error al insertar/actualizar acta:', error);
    const errorMessage = error.code === ' 23502' ? 'Faltan campos requeridos' :
      error.code === '42P01' ? 'Tabla no encontrada' :
        'Error interno del servidor';
    res.status(500).json({
      error: errorMessage,
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Servidor ejecutándose en el puerto ${PORT}`);
});