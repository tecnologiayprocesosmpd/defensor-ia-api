# API REST SAEPBI

API REST para consumir datos desde una intranet y mantener la privacidad de los datos. Se conecta a una base de datos PostgreSQL para gestionar vencimientos de beneficios.

## Requisitos

- Node.js (versión 14 o superior)
- npm (Node Package Manager)
- PostgreSQL (versión 10 o superior)

## Instalación

1. Clonar el repositorio o descargar los archivos

2. Instalar las dependencias:
```bash
npm install
```

3. Configurar las variables de entorno:
El archivo `.env` ya contiene la configuración necesaria para la conexión a la base de datos.

## Ejecución

Para iniciar el servidor en modo desarrollo:
```bash
npm run dev
```

Para iniciar el servidor en modo producción:
```bash
npm start
```

El servidor se ejecutará por defecto en el puerto 3000.

## Endpoints

### GET /api/ObtenerVencimientos

Obtiene la lista de vencimientos de beneficios con sus observaciones.

Respuesta: Array de objetos con la siguiente estructura:
- CentroJudicial
- Sistema
- Oficina
- Expediente
- Persona
- Documento
- CaracterParte
- Grupo
- Alojamiento
- Pena
- Delito
- Cumpl12deCondena
- Cumpl23deCondena
- Cumpl6Meses
- Cumpl3Meses
- CumplimientoCondena
- VencimientosBenefResp
- ExpedienteFisc
- VencimientosBenefEstado
- observaciones
- procid
- partid

### POST /api/InsertarObservacion

Inserta una nueva observación para un vencimiento de beneficio.

Cuerpo de la solicitud (JSON):
```json
{
  "obspro": 123,
  "obspar": 456,
  "obscen": "Centro Judicial",
  "obsexp": "Número de Expediente",
  "observaciones": "Texto de la observación"
}
```

Respuesta exitosa:
```json
{
  "mensaje": "Observación insertada correctamente"
}
```