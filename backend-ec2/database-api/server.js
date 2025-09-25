// database-api/server.js
require('./tracing'); // Initialize OpenTelemetry first

const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const pino = require('pino');
const pinoHttp = require('pino-http');
const client = require('prom-client'); // Prometheus client
const { trace, context } = require('@opentelemetry/api'); // For Pino mixin

const db = require("./db/index"); // Path to your DB connection logic
const mainApiRouter = require("./api/index"); // Main router for all resources

// Pino Logger Setup
const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
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
  // autoLogging: { ignore: (req) => req.url === '/metrics' || req.url === '/health' },
});

const app = express();
app.locals.logger = logger; // Make logger available via req.app.locals.logger

// Database Connection - pass the app instance
db.connect(app);

// Core Middleware
app.use(httpLogger);
app.use(cors()); // Enable CORS for all routes
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));

// Prometheus Metrics Setup
const promRegistry = new client.Registry();
client.collectDefaultMetrics({ register: promRegistry, prefix: 'database_api_nodejs_' });

const httpRequestDurationSeconds = new client.Histogram({
  name: 'database_api_http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds for database-api',
  labelNames: ['method', 'route', 'code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  registers: [promRegistry],
});
const httpRequestsTotal = new client.Counter({
  name: 'database_api_http_requests_total',
  help: 'Total number of HTTP requests for database-api',
  labelNames: ['method', 'route', 'code'],
  registers: [promRegistry],
});

// Metrics recording middleware
app.use((req, res, next) => {
  const startEpoch = Date.now();
  res.on('finish', () => {
    const durationSeconds = (Date.now() - startEpoch) / 1000;
    // Use originalUrl for more robust route matching if sub-routers are used extensively
    const routePath = req.route ? (req.baseUrl + req.route.path) : (req.baseUrl || '') + (req.path || 'unknown_route');
    httpRequestDurationSeconds
      .labels(req.method, routePath, res.statusCode)
      .observe(durationSeconds);
    httpRequestsTotal
      .labels(req.method, routePath, res.statusCode)
      .inc();
  });
  next();
});

// Standard Endpoints
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', promRegistry.contentType);
  res.end(await promRegistry.metrics());
});
app.get('/health', (req, res) => {
  res.status(200).send({ status: 'UP', message: 'Database API is healthy' });
});

// Mount the main API router
// All routes defined in api/index.js (like /todos) will be available at the root
// e.g., POST /todos, GET /todos, GET /todos/:id
app.use('/', mainApiRouter);

// Centralized Error Handling
app.use((err, req, res, next) => {
  const errorLogger = req.log || logger;
  errorLogger.error({ err, reqId: req.id }, 'Database API: Unhandled error occurred');
  if (res.headersSent) {
    return next(err);
  }
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    message: err.message || 'Internal Server Error',
    // stack: process.env.NODE_ENV === 'development' ? err.stack : undefined, // Optional for dev
  });
});

// 404 Handler for unmatched routes
app.use((req, res) => {
  const errorLogger = req.log || logger;
  errorLogger.warn({ reqId: req.id, url: req.originalUrl }, 'Database API: Resource not found (404)');
  res.status(404).json({ success: false, message: 'Not Found' });
});

// Start Server (after DB is ready)
const PORT = parseInt(process.env.PORT, 10) || 3002;
app.on("ready", () => {
  app.listen(PORT, () => {
    logger.info(`Database API service running on port ${PORT}`);
    logger.info(`Connect to MongoDB at: ${process.env.MONGODB_URI}`);
  });
});

// Graceful shutdown is handled by tracing.js
