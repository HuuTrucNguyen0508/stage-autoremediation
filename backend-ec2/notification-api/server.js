// notification-api/server.js
require('./tracing'); // Initialize OpenTelemetry

const express = require("express");
const bodyParser = require("body-parser");
const client = require('prom-client');
const pino = require('pino');
const pinoHttp = require('pino-http');
const axios = require('axios'); // For calling database-api
const { trace, context } = require('@opentelemetry/api');

// NO MORE DB or MODEL requires here for direct Mongo access for todos

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  mixin() {
    const span = trace.getSpan(context.active());
    if (!span) return {};
    const { traceId, spanId, traceFlags } = span.spanContext();
    return { trace_id: traceId, span_id: spanId, trace_flags: traceFlags ? `0${traceFlags.toString(16)}` : undefined };
  },
  timestamp: pino.stdTimeFunctions.isoTime,
});
const httpLogger = pinoHttp({ logger });

const app = express();
app.locals.logger = logger;

// NO MORE db.connect(app);

app.use(httpLogger);
app.use(bodyParser.json());

// Prometheus Metrics Setup
const promRegistry = new client.Registry();
client.collectDefaultMetrics({ register: promRegistry, prefix: 'notification_api_nodejs_' });
const httpRequestDurationSeconds = new client.Histogram({ name: 'notification_api_http_request_duration_seconds', help: 'Duration of HTTP requests in seconds for notification-api', labelNames: ['method', 'route', 'code'], buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5], registers: [promRegistry] });
const httpRequestsTotal = new client.Counter({ name: 'notification_api_http_requests_total', help: 'Total number of HTTP requests for notification-api', labelNames: ['method', 'route', 'code'], registers: [promRegistry] });

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

app.get('/metrics', async (req, res) => res.set('Content-Type', promRegistry.contentType).end(await promRegistry.metrics()));
app.get('/health', (req, res) => res.status(200).send({ status: 'UP', message: 'Notification API is healthy' }));

// Original /notify endpoint - remains the same
app.post("/notify", (req, res) => {
  const currentLogger = req.log || logger;
  currentLogger.info({ notification: req.body }, "📢 Notification received");
  res.status(200).send({ success: true });
});

// Updated /todos route to call database-api
const DATABASE_API_BASE_URL = process.env.DATABASE_API_URL || 'http://database-api:3002';
const serviceTracer = trace.getTracer("notification-api-service-tracer");

app.get("/todos", async (req, res) => {
  const currentLogger = req.log || logger;
  currentLogger.info("Notification API: Received request for /todos, calling Database API.");
  const span = serviceTracer.startSpan("notification_api.getTodosViaDbApi");
  try {
    span.addEvent("Calling Database API to fetch todos", {"http.url": `${DATABASE_API_BASE_URL}/todos`});
    const dbApiResponse = await axios.get(`${DATABASE_API_BASE_URL}/todos`);
    span.addEvent("Database API call successful", {"http.status_code": dbApiResponse.status});

    if (!dbApiResponse.data || !dbApiResponse.data.success || !Array.isArray(dbApiResponse.data.data)) {
        const errorMessage = (dbApiResponse.data && dbApiResponse.data.message) || "Database API failed to fetch todos or returned unexpected format.";
        span.setStatus({ code: trace.SpanStatusCode.ERROR, message: errorMessage });
        currentLogger.error({error: dbApiResponse.data, status: dbApiResponse.status}, "Notification API: Error response from Database API.");
        return res.status(dbApiResponse.status || 500).json({ success: false, message: "Failed to fetch todos via database service.", error: errorMessage});
    }
    const todos = dbApiResponse.data.data;
    currentLogger.info({ count: todos.length }, "Notification API: Todos successfully fetched via Database API.");
    res.status(200).json({ success: true, message: "Todos fetched by notification-api via database-api", data: todos });
  } catch (error) {
    span.recordException(error);
    span.setStatus({ code: trace.SpanStatusCode.ERROR, message: error.message });
    currentLogger.error({ err: error }, "Notification API: Error calling Database API for /todos.");
    const statusCode = error.isAxiosError && error.response ? error.response.status : 500;
    const errMessage = error.isAxiosError && error.response && error.response.data ? (error.response.data.message || error.response.data.error || "Error calling downstream service") : error.message;
    res.status(statusCode).json({ success: false, message: "Failed to fetch todos.", error: errMessage });
  } finally {
    span.end();
  }
});

const PORT = parseInt(process.env.PORT, 10) || 4000;
app.listen(PORT, () => { // Server starts directly
  logger.info(`📣 Notification API service running on port ${PORT}`);
});

// Graceful shutdown (from tracing.js or similar)
