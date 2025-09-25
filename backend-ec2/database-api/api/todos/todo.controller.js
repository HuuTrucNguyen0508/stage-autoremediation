// database-api/api/todos/todo.controller.js
const { Todo } = require('../../models/Todo.model');
const { trace, SpanStatusCode, context: opentelemetryContext } = require("@opentelemetry/api"); // Corrected import

const getTracer = () => trace.getTracer("database-api-todo-controller");

// Basic response helpers (ensure these are defined or required from a utility file)
const sendSuccess = (res, data, message = "Success", statusCode = 200) => res.status(statusCode).json({ success: true, message, data });
const sendError = (res, message = "Error", errorDetails = null, statusCode = 500) => res.status(statusCode).json({ success: false, message, error: errorDetails || message });


exports.createTodo = async (req, res) => {
  const currentLogger = req.log || (req.app && req.app.locals && req.app.locals.logger) || console;
  const tracer = getTracer();
  const span = tracer.startSpan("db_api.createTodo");

  // Using opentelemetryContext.with to ensure the span is active for the async operations
  await opentelemetryContext.with(trace.setSpan(opentelemetryContext.active(), span), async () => {
    try {
      if (!req.body.text || typeof req.body.text !== 'string' || req.body.text.trim() === '') {
          span.setStatus({ code: SpanStatusCode.ERROR, message: "Text is required" }); // Use SpanStatusCode
          return sendError(res, "Text is required for todo", null, 400);
      }
      const todo = new Todo({ text: req.body.text.trim() });
      span.addEvent("Attempting to save todo to database");
      const savedTodo = await todo.save();
      span.addEvent("Todo saved successfully", { todoId: savedTodo._id.toString() });
      currentLogger.info({ todoId: savedTodo._id }, "Database API: Todo created");
      span.setStatus({ code: SpanStatusCode.OK }); // Set OK status
      sendSuccess(res, savedTodo, "Todo created successfully", 201);
    } catch (e) {
      span.recordException(e);
      span.setStatus({ code: SpanStatusCode.ERROR, message: e.message }); // Use SpanStatusCode
      currentLogger.error({ err: e, body: req.body }, "Database API: Error creating todo");
      sendError(res, "Error creating todo", e.message, 500);
    } finally {
      span.end();
    }
  });
};

exports.getAllTodos = async (req, res) => {
  const currentLogger = req.log || (req.app && req.app.locals && req.app.locals.logger) || console;
  const tracer = getTracer();
  const span = tracer.startSpan("db_api.getAllTodos");

  await opentelemetryContext.with(trace.setSpan(opentelemetryContext.active(), span), async () => {
    try {
      span.addEvent("Querying database for all todos with projection");
      
      // MODIFIED HERE: Use projection to exclude fields
      const todos = await Todo.find({}, '-completed -completedAt -updatedAt -__v');

      span.addEvent("Todos fetched from database", { count: todos.length });
      currentLogger.info({ count: todos.length }, "Database API: Todos fetched");
      span.setStatus({ code: SpanStatusCode.OK }); // Set OK status
      sendSuccess(res, todos, "Todos fetched successfully");
    } catch (e) {
      span.recordException(e);
      span.setStatus({ code: SpanStatusCode.ERROR, message: e.message }); // Use SpanStatusCode
      currentLogger.error({ err: e }, "Database API: Error fetching todos");
      sendError(res, "Error fetching todos", e.message, 500);
    } finally {
      span.end();
    }
  });
};

exports.getTodoById = async (req, res) => {
    const currentLogger = req.log || (req.app && req.app.locals && req.app.locals.logger) || console;
    const tracer = getTracer();
    const span = tracer.startSpan("db_api.getTodoById");

    await opentelemetryContext.with(trace.setSpan(opentelemetryContext.active(), span), async () => {
      try {
          // For fetching a single item, you usually want all details.
          // If you want this lean too, add projection: '-completed -completedAt -updatedAt -__v'
          const todo = await Todo.findById(req.params.id);

          if (!todo) {
              span.setStatus({ code: SpanStatusCode.ERROR, message: "Todo not found" }); // Use SpanStatusCode
              return sendError(res, "Todo not found", null, 404);
          }
          span.addEvent("Todo fetched by ID", { todoId: todo._id.toString() });
          currentLogger.info({ todoId: todo._id }, "Database API: Todo fetched by ID");
          span.setStatus({ code: SpanStatusCode.OK }); // Set OK status
          sendSuccess(res, todo, "Todo fetched successfully");
      } catch (e) {
          span.recordException(e);
          span.setStatus({ code: SpanStatusCode.ERROR, message: e.message }); // Use SpanStatusCode
          currentLogger.error({ err: e, todoId: req.params.id }, "Database API: Error fetching todo by ID");
          if (e.name === 'CastError' && e.kind === 'ObjectId') { // Handle invalid ID format
              return sendError(res, "Invalid Todo ID format", e.message, 400);
          }
          sendError(res, "Error fetching todo by ID", e.message, 500);
      } finally {
          span.end();
      }
    });
};