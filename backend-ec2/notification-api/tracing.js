// notification-api/tracing.js
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { JaegerExporter } = require('@opentelemetry/exporter-jaeger');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');
const { B3Propagator, B3InjectEncoding } = require('@opentelemetry/propagator-b3');

const serviceName = process.env.OTEL_SERVICE_NAME || 'notification-api'; // Default
const serviceVersion = process.env.SERVICE_VERSION || '1.0.0';
const jaegerEndpoint = process.env.JAEGER_ENDPOINT || 'http://jaeger:14268/api/traces';

const jaegerExporter = new JaegerExporter({ endpoint: jaegerEndpoint });

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: serviceName,
    [SemanticResourceAttributes.SERVICE_VERSION]: serviceVersion,
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'development',
  }),
  traceExporter: jaegerExporter,
  instrumentations: [getNodeAutoInstrumentations()],
  textMapPropagator: new B3Propagator({ injectEncoding: B3InjectEncoding.MULTI_HEADER }),
});

try {
  sdk.start();
  console.log(`${serviceName}: OpenTelemetry SDK started successfully.`);
} catch (error) {
  console.error(`${serviceName}: Error starting OpenTelemetry SDK:`, error);
  process.exit(1);
}

const gracefulShutdown = (signal) => {
  console.log(`${serviceName}: ${signal} signal received. Shutting down OpenTelemetry SDK...`);
  sdk.shutdown()
    .then(() => console.log(`${serviceName}: OpenTelemetry SDK shut down successfully.`))
    .catch((error) => console.error(`${serviceName}: Error shutting down OpenTelemetry SDK:`, error))
    .finally(() => process.exit(0));
};
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
