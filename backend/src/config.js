import { z } from 'zod';

/**
 * Environment configuration, validated with Zod.
 *
 * Never put secrets in code. Provide them via environment variables and
 * document their names in `.env.example`.
 */
const envSchema = z.object({
  PORT: z.coerce.number().int().positive().default(8080),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
});

export function loadConfig(env = process.env) {
  return envSchema.parse(env);
}
