// backend/routes/index.js

const express = require("express");
const axios = require("axios");
const api = require("@opentelemetry/api"); // OpenTelemetry API
const serverResponses = require("../utils/helpers/responses");
const messages = require("../config/messages");
const { Todo } = require("../models/todos/todo");

// This function will be exported and called from server.js
const routes = (app, logger) => { // logger is passed in
  const router = express.Router();
  const tracer = api.trace.getTracer("todo-service-tracer"); // More descriptive tracer name

  // Middleware to enrich logs with span information if not already done by pino's mixin
  // This is a fallback or explicit way to ensure trace context is available for manual logging calls
  // router.use((req, res, next) => {
  //   const span = api.trace.getSpan(api.context.active());
  //   if (span) {
  //     const { traceId, spanId } = span.spanContext();
  //     req.log = logger.child({ trace_id: traceId, span_id: spanId }); // Creates a child logger with these fields
  //   } else {
  //     req.log = logger;
  //   }
  //   next();
  // });
  // Note: The pino mixin in server.js should already handle adding trace_id and span_id
  // to logs made through the main logger instance. If you use `req.log` as defined by `pino-http`,
  // it should also inherit this context.

  router.post("/todos", async (req, res) => {
    // If using pino-http, req.log is available and pre-configured with request context
    const currentLogger = req.log || logger; // Prefer req.log if available from pino-http

    currentLogger.info({ body: req.body }, "Received request to create a new todo");

    // Start the main span for this handler
    const parentSpan = tracer.startSpan("create_todo_handler");

    try {
      const todo = new Todo({
        text: req.body.text,
      });

      // Manually add event to span
      parentSpan.addEvent("Attempting to save new todo to database");
      const result = await todo.save();
      parentSpan.addEvent("Successfully saved todo to database", { todoId: result._id.toString() });
      currentLogger.info({ todoId: result._id, todoText: result.text }, "Todo created successfully in DB");

      // Send notification (as a child span)
      const notificationSpan = tracer.startSpan("send_create_todo_notification", {
        // attributes for the span
        "notification.type": "todo_created",
        "notification.todo_id": result._id.toString(),
      }, api.context.active()); // Explicitly set context if needed, though usually automatic

      try {
        currentLogger.info("Attempting to send notification for new todo");
        notificationSpan.addEvent("Calling notification API");

        await axios.post("http://notification-api:4000/notify", {
          message: `New todo created: ${result.text}`,
          todoId: result._id.toString(),
        });

        notificationSpan.setAttribute("notification.status", "success");
        notificationSpan.addEvent("Notification API call successful");
        currentLogger.info("Notification sent successfully for new todo");
      } catch (error) {
        notificationSpan.recordException(error); // Record error on the span
        notificationSpan.setStatus({ code: api.SpanStatusCode.ERROR, message: error.message });
        notificationSpan.setAttribute("notification.status", "failed");
        currentLogger.error({ err: error, todoId: result._id.toString() }, "Failed to send notification for new todo");
        // Decide if this error should make the whole /todos request fail or just log it
        // For now, we'll let the main request succeed even if notification fails.
      } finally {
        notificationSpan.end();
      }

      serverResponses.sendSuccess(res, messages.SUCCESSFUL, result);
    } catch (e) {
      parentSpan.recordException(e); // Record the exception on the span
      parentSpan.setStatus({ code: api.SpanStatusCode.ERROR, message: e.message });
      currentLogger.error({ err: e, body: req.body }, "Error creating todo");
      serverResponses.sendError(res, messages.BAD_REQUEST, e);
    } finally {
      parentSpan.end(); // Always end the parent span
    }
  });

  router.get("/", async (req, res) => {
    const currentLogger = req.log || logger;
    currentLogger.info("Received request to get all todos");

    const parentSpan = tracer.startSpan("get_all_todos_handler");

    try {
      parentSpan.addEvent("Querying database for all todos");
      const todos = await Todo.find({}, { __v: 0 });
      parentSpan.addEvent("Successfully fetched todos from database", { count: todos.length });
      currentLogger.info({ count: todos.length }, "Successfully fetched todos");
      serverResponses.sendSuccess(res, messages.SUCCESSFUL, todos);
    } catch (e) {
      parentSpan.recordException(e);
      parentSpan.setStatus({ code: api.SpanStatusCode.ERROR, message: e.message });
      currentLogger.error({ err: e }, "Error fetching todos");
      serverResponses.sendError(res, messages.BAD_REQUEST, e);
    } finally {
      parentSpan.end();
    }
  });

  router.post("/notifications", async (req, res) => {
    const currentLogger = req.log || logger;
    const { message } = req.body;

    if (!message) {
      currentLogger.warn("Manual notification request received without a message");
      return serverResponses.sendError(res, messages.BAD_REQUEST, "Message is required for notification.");
    }

    currentLogger.info({ notificationMessage: message }, "Received request to send a manual notification");
    const parentSpan = tracer.startSpan("send_manual_notification_handler");
    parentSpan.setAttribute("notification.message", message);

    // Child span for the actual HTTP call
    const httpCallSpan = tracer.startSpan("send_manual_notification_http_request", {
       "http.method": "POST",
       "http.url": "http://notification-api:4000/notify",
    }, api.context.active());

    try {
      currentLogger.info("Attempting to send manual notification via API");
      httpCallSpan.addEvent("Calling notification API for manual notification");

      const response = await axios.post("http://notification-api:4000/notify", {
        message: message,
      });

      httpCallSpan.setAttribute("http.status_code", response.status);
      httpCallSpan.addEvent("Manual notification API call successful");
      currentLogger.info({ responseData: response.data }, "Manual notification sent successfully");
      serverResponses.sendSuccess(res, messages.SUCCESSFUL, response.data);
      parentSpan.setStatus({ code: api.SpanStatusCode.OK });
    } catch (error) {
      httpCallSpan.recordException(error);
      httpCallSpan.setStatus({ code: api.SpanStatusCode.ERROR, message: error.message });
      if (error.response) {
        httpCallSpan.setAttribute("http.status_code", error.response.status);
      }
      currentLogger.error({ err: error, notificationMessage: message }, "Error sending manual notification");
      serverResponses.sendError(res, messages.BAD_REQUEST, error.message || "Failed to send notification");
      parentSpan.setStatus({ code: api.SpanStatusCode.ERROR, message: error.message });
    } finally {
      httpCallSpan.end();
      parentSpan.end();
    }
  });

  // Mount the router on the app, with a base path
  app.use("/api", router);
};

module.exports = routes;
