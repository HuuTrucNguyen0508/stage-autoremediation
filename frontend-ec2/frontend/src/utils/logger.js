// File: frontend-ec2/frontend/src/utils/logger.js

/**
 * Sends a log message to the NGINX logging endpoint.
 * Now includes a Correlation ID for process tracing.
 * @param {string} level - The log level ('INFO', 'WARN', 'ERROR').
 * @param {string} message - The primary log message.
 * @param {object} context - Additional data for context.
 * @param {string} correlationId - A unique ID to group related log messages.
 */
const sendLog = (level, message, context = {}, correlationId = 'none') => {
  // We now add both a Correlation ID and bracketed Level for emphasis and parsing.
  const logPayload = `CORRELATION_ID=[${correlationId}] LEVEL=[${level}] MESSAGE="${message}" CONTEXT=${JSON.stringify(
    context
  )}`;

  // The fetch call remains the same.
  fetch('/log-event', {
    method: 'POST',
    headers: {
      'Content-Type': 'text/plain;charset=UTF-8',
    },
    body: logPayload,
    keepalive: true,
  }).catch((error) => {
    console.error('Failed to send log to server:', error);
  });

  // Also log to the browser's console for easier development debugging.
  const browserLog = console[level.toLowerCase()] || console.log;
  browserLog(`[${correlationId}] [SENT TO SERVER LOGS] [${level}] ${message}`, context);
};

// Update the logger object methods to accept and pass the optional correlationId.
const logger = {
  info: (message, context, correlationId) => sendLog('INFO', message, context, correlationId),
  warn: (message, context, correlationId) => sendLog('WARN', message, context, correlationId),
  error: (message, context, correlationId) => sendLog('ERROR', message, context, correlationId),
};

export default logger;
