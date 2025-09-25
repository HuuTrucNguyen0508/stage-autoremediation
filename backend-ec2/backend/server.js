// backend/server.js

// 1. OpenTelemetry Tracing
require("./tracing");

// 2. Configuration (if any non-DB specific config remains)
// require("./config/config"); // Assuming this has messages, etc.

// 3. Module Imports
const express = require("express");
const path = require("path"); // If using express.static
const cookieParser = require("cookie-parser");
const bodyParser = require("body-parser");
const cors = require("cors");
const { trace, context } = require('@opentelemetry/api');
const pino = require('pino');
const pinoHttp = require('pino-http');
const client = require('prom-client');

const mainApiRouter = require("./api/index"); // Make sure backend/api/index.js exists

// 4. Pino Logger Setup
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  serializers: { err: pino.stdSerializers.err, req: pino.stdSerializers.req, res: pino.stdSerializers.res },
  mixin() {
    const span = trace.getSpan(context.active());
    if (!span) return {};
    const { traceId, spanId, traceFlags } = span.spanContext();
    return {
      trace_id: traceId,
      span_id: spanId,
      trace_flags: traceFlags ? `0${traceFlags.toString(16)}` : undefined,
    };
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});

const httpLogger = pinoHttp({
  logger: logger,
  autoLogging: { ignore: (req) => req.url === '/metrics' || req.url === '/health' },
});

// 5. Express Application Setup
const app = express();
app.locals.logger = logger; // For access in controllers: req.app.locals.logger

// --- NO DIRECT DATABASE CONNECTION (db.connect(app) IS REMOVED) ---

// 6. Core Middleware
app.use(httpLogger);
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());

// 7. Prometheus Metrics Setup
const promRegistry = new client.Registry();
client.collectDefaultMetrics({ register: promRegistry, prefix: 'backend_api_nodejs_' }); // Changed prefix

const httpRequestDurationSeconds = new client.Histogram({
  name: 'backend_api_http_request_duration_seconds', // Changed name
  help: 'Duration of HTTP requests in seconds for backend-api',
  labelNames: ['method', 'route', 'code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  registers: [promRegistry],
});
const httpRequestsTotal = new client.Counter({
  name: 'backend_api_http_requests_total', // Changed name
  help: 'Total number of HTTP requests for backend-api',
  labelNames: ['method', 'route', 'code'],
  registers: [promRegistry],
});

app.use((req, res, next) => {
  const startEpoch = Date.now();
  res.on('finish', () => {
    const durationSeconds = (Date.now() - startEpoch) / 1000;
    const routePath = req.route ? (req.baseUrl + req.route.path) : (req.baseUrl || '') + (req.path || 'unknown_route');
    httpRequestDurationSeconds.labels(req.method, routePath, res.statusCode).observe(durationSeconds);
    httpRequestsTotal.labels(req.method, routePath, res.statusCode).inc();
  });
  next();
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promRegistry.contentType);
  res.end(await promRegistry.metrics());
});
app.get('/health', (req, res) => {
  res.status(200).send({ status: 'UP', message: 'Backend API is healthy' });
});

// 8. Application API Routes
// Ensure backend/api/index.js exists and mounts your refactored todo.routes.js
// (and notification.routes.js if you kept that test endpoint)
app.use('/api', mainApiRouter);

// 9. Static Files (If backend-api still serves something from a 'public' folder)
// app.use(express.static(path.join(__dirname, "public")));

// 10. Centralized Error Handling & 404
app.use((err, req, res, next) => {
  const errorLogger = req.log || logger;
  errorLogger.error({ err, reqId: req.id }, 'Backend API: Unhandled error');
  if (res.headersSent) { return next(err); }
  const statusCode = err.statusCode || 500;
  const message = statusCode === 500 && process.env.NODE_ENV === 'production' ? 'Internal Server Error' : err.message;
  res.status(statusCode).json({ success: false, error: { message } });
});
app.use((req, res) => {
  const errorLogger = req.log || logger;
  errorLogger.warn({ reqId: req.id, url: req.originalUrl }, 'Backend API: Resource not found (404)');
  res.status(404).json({ success: false, error: { message: 'Not Found' } });
});

// 11. Start Server
const PORT = parseInt(process.env.PORT, 10) || 8080;
app.listen(PORT, () => { // Server starts directly, no app.on('ready')
  logger.info(`Backend API service (formerly backend) running on port ${PORT}`);
});

// Graceful shutdown handled by tracing.js
module.exports = app;
