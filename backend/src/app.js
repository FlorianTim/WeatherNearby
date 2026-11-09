import express from 'express';
import { z } from 'zod';

/**
 * Example request schema. Use Zod schemas for every request body.
 */
const echoSchema = z.object({
  message: z.string().min(1).max(500),
});

/**
 * Creates the Express app (separated from the listener for testability).
 */
export function createApp() {
  const app = express();

  app.disable('x-powered-by');
  app.use(express.json({ limit: '100kb' }));

  app.get('/health', (_req, res) => {
    res.json({ status: 'ok' });
  });

  app.get('/v1/config', (_req, res) => {
    // Only expose non-sensitive, client-safe configuration here.
    res.json({ apiVersion: 'v1' });
  });

  app.post('/v1/echo', (req, res) => {
    const parsed = echoSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'invalid_request' });
      return;
    }
    res.json({ message: parsed.data.message });
  });

  // Fallback error handler. Never leak internals or log request secrets.
  // eslint-disable-next-line no-unused-vars
  app.use((err, _req, res, _next) => {
    res.status(500).json({ error: 'internal_error' });
  });

  return app;
}
