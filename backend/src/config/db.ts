import sql from "mssql";
import { env } from "./env.js";
import { logger } from "../utils/logger.js";

// DECIMAL/NUMERIC columns come back as JS numbers by default, which risks
// precision loss for money values. Returning them as strings instead means
// they can be parsed straight into a Decimal (see src/utils/money.ts) without
// ever passing through a JS `number`.
// @types/mssql doesn't declare `valueHandler` yet, even though it exists at
// runtime in the mssql package itself - hence the cast.
(sql as any).valueHandler.set(sql.TYPES.Decimal, (value: unknown) => value);
(sql as any).valueHandler.set(sql.TYPES.Numeric, (value: unknown) => value);

const config: sql.config = {
  server: env.DB_SERVER,
  port: env.DB_PORT,
  database: env.DB_NAME,
  user: env.DB_USER,
  password: env.DB_PASSWORD,
  options: {
    trustServerCertificate: env.DB_TRUST_SERVER_CERTIFICATE,
    encrypt: true,
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000,
  },
};

let pool: sql.ConnectionPool | null = null;

export async function getPool(): Promise<sql.ConnectionPool> {
  if (pool) return pool;
  pool = await new sql.ConnectionPool(config).connect();
  logger.info(
    { server: env.DB_SERVER, database: env.DB_NAME },
    "Connected to SQL Server"
  );
  return pool;
}

export { sql };
