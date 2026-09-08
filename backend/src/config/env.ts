import "dotenv/config";
import { z } from "zod";

// Validating env vars at startup means a missing/wrong value fails loudly
// and immediately, instead of causing a confusing error deep inside a request.
const envSchema = z.object({
  PORT: z.coerce.number().default(4000),
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),

  DB_SERVER: z.string().min(1, "DB_SERVER is required"),
  DB_PORT: z.coerce.number().default(1433),
  DB_NAME: z.string().min(1, "DB_NAME is required"),
  DB_USER: z.string().min(1, "DB_USER is required"),
  DB_PASSWORD: z.string().min(1, "DB_PASSWORD is required"),
  DB_TRUST_SERVER_CERTIFICATE: z
    .string()
    .default("false")
    .transform((v) => v === "true"),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error("Invalid environment configuration:");
  console.error(parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const env = parsed.data;
