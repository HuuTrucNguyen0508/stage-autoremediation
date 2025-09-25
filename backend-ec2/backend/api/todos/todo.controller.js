// backend/api/todos/todo.controller.js
const axios = require('axios');
// Correctly import trace and SpanStatusCode from @opentelemetry/api
const { trace, SpanStatusCode, context: opentelemetryContext } = require("@opentelemetry/api");
const serverResponses = require('../../utils/helpers/responses'); // Adjust path if needed
const messages = require('../../config/messages');     // Adjust path if needed

const DATABASE_API_BASE_URL = process.env.DATABASE_API_URL || 'http://database-api:3002';
const NOTIFICATION_API_BASE_URL = process.env.NOTIFICATION_API_URL || 'http://notification-api:4000';

const getTracer = () => trace.getTracer("backend-api-todo-controller"); // Consistent tracer name

exports.createTodo = async (req, res) => {
  const currentLogger = req.log || (req.app && req.app.locals && req.app.locals.logger) || console;
  const tracer = getTracer();
  // Start a new span. It will automatically become the active span in the current context.
  const parentSpan = tracer.startSpan("backend.controller.createTodo");

  // It's good practice to run the core logic within the context of this span
  await opentelemetryContext.with(trace.setSpan(opentelemetryContext.active(), parentSpan), async () => {
    try {
      if (!req.body.text || typeof req.body.text !== 'string' || req.body.text.trim() === '') {
          parentSpan.setStatus({ code: SpanStatusCode.ERROR, message: "Todo text is required." });
          return serverResponses.sendError(res, messages.BAD_REQUEST, "Todo text is required.", 400);
      }

      currentLogger.info({ body: req.body }, "Backend API: Received request to create todo. Calling Database API.");
      parentSpan.addEvent("Calling Database API to create todo", { "http.url": `${DATABASE_API_BASE_URL}/todos` });

      // The HTTP client instrumentation (from getNodeAutoInstrumentations)
      // should automatically create a child span for this axios call and propagate context.
      const dbApiResponse = await axios.post(`${DATABASE_API_BASE_URL}/todos`, { text: req.body.text.trim() });
      parentSpan.addEvent("Database API call successful", { "http.status_code": dbApiResponse.status });

      if (!dbApiResponse.data || !dbApiResponse.data.success || !dbApiResponse.data.data) {
          const errorMessage = (dbApiResponse.data && dbApiResponse.data.message) || "Database API failed to create todo or returned unexpected format.";
          parentSpan.setStatus({ code: SpanStatusCode.ERROR, message: errorMessage });
          currentLogger.error({ error: dbApiResponse.data, status: dbApiResponse.status }, "Backend API: Error response from Database API during create.");
          // Pass the actual status from dbApiResponse if available
          return serverResponses.sendError(res, "Failed to create todo via database service.", errorMessage, dbApiResponse.status || 500);
      }
      const newTodo = dbApiResponse.data.data;
      currentLogger.info({ todo: newTodo }, "Backend API: Todo created via Database API. Attempting to notify.");

      parentSpan.setStatus({ code: SpanStatusCode.OK });
      serverResponses.sendSuccess(res, messages.SUCCESSFUL, newTodo, 201);

    } catch (error) {
      parentSpan.recordException(error);
      parentSpan.setStatus({ code: SpanStatusCode.ERROR, message: error.message }); // Using SpanStatusCode.ERROR
      currentLogger.error({ err: error, body: req.body }, "Backend API: Error in createTodo controller.");
      
      const statusCode = error.isAxiosError && error.response ? error.response.status : 500;
      const errMessage = error.isAxiosError && error.response && error.response.data ? (error.response.data.message || error.response.data.error || "Error calling downstream service") : error.message;
      serverResponses.sendError(res, "Failed to create todo.", errMessage, statusCode);
    } finally {
      parentSpan.end();
    }
  }); // End of with context
};

exports.getAllTodos = async (req, res) => {
  const currentLogger = req.log || (req.app && req.app.locals && req.app.locals.logger) || console;
  const tracer = getTracer();
  const parentSpan = tracer.startSpan("backend.controller.getAllTodos");

  await opentelemetryContext.with(trace.setSpan(opentelemetryContext.active(), parentSpan), async () => {
    try {
      currentLogger.info("Backend API: Received request to get all todos. Calling Database API.");
      parentSpan.addEvent("Calling Database API to get all todos", { "http.url": `${DATABASE_API_BASE_URL}/todos` });

      const dbApiResponse = await axios.get(`${DATABASE_API_BASE_URL}/todos`);
      parentSpan.addEvent("Database API call successful", { "http.status_code": dbApiResponse.status });

      if (!dbApiResponse.data || !dbApiResponse.data.success || !Array.isArray(dbApiResponse.data.data)) {
          const errorMessage = (dbApiResponse.data && dbApiResponse.data.message) || "Database API failed to fetch todos or returned unexpected format.";
          parentSpan.setStatus({ code: SpanStatusCode.ERROR, message: errorMessage }); // Using SpanStatusCode.ERROR
          currentLogger.error({ error: dbApiResponse.data, status: dbApiResponse.status }, "Backend API: Error response from Database API during get all.");
          return serverResponses.sendError(res, "Failed to fetch todos from database service.", errorMessage, dbApiResponse.status || 500);
      }
      const todos = dbApiResponse.data.data;
      currentLogger.info({ count: todos.length }, "Backend API: Todos fetched via Database API.");
      parentSpan.setStatus({ code: SpanStatusCode.OK });
      serverResponses.sendSuccess(res, messages.SUCCESSFUL, todos);
    } catch (error) {
      parentSpan.recordException(error);
      parentSpan.setStatus({ code: SpanStatusCode.ERROR, message: error.message }); // Using SpanStatusCode.ERROR
      currentLogger.error({ err: error }, "Backend API: Error in getAllTodos controller.");

      const statusCode = error.isAxiosError && error.response ? error.response.status : 500;
      const errMessage = error.isAxiosError && error.response && error.response.data ? (error.response.data.message || error.response.data.error || "Error calling downstream service") : error.message;
      serverResponses.sendError(res, "Failed to fetch todos.", errMessage, statusCode);
    } finally {
      parentSpan.end();
    }
  }); // End of with context
};
