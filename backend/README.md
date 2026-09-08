# IVConnect backend

Express + TypeScript API for the IVConnect Employee & Business Portal.
Connects to MSSQL via the `mssql` package, with decimal-safe handling for
payroll amounts (see `src/utils/money.ts`).

## Run it locally

Requires Node.js 18+ and a running SQL Server (see your local Docker setup).

1. Copy the example environment file and fill in your real values:

   ```bash
   cp .env.example .env
   ```

   For a local Docker SQL Server started the way we set it up, `.env`
   should already match `.env.example` as long as `DB_PASSWORD` is the
   same password you used in your `docker run` command.

2. Install dependencies:

   ```bash
   npm install
   ```

3. Start the dev server (auto-restarts on file changes):

   ```bash
   npm run dev
   ```

You should see `IVConnect backend listening on http://localhost:4000`.

## Try it out

With the IVConnect schema deployed to your database (the baseline script
you already ran), open these in a browser or with curl:

- `http://localhost:4000/api/health` — confirms the API is up and can
  reach the database.
- `http://localhost:4000/api/roles` — returns the same 7 roles
  (Employee, Manager, HR Admin, Payroll Admin, Sales Rep, Sales Manager,
  System Admin) you already verified directly in SQL, now served through
  the API.

## What changes when you move to a real server

Only the values in `.env` — server address, port, username, password, and
whether to trust a self-signed certificate. None of the code in `src/`
needs to change. See `.env.example` for what each value means.

## Project structure

```
src/
  server.ts             entry point - starts the HTTP server
  app.ts                 Express app setup - middleware and route mounting
  config/
    env.ts                loads and validates .env with Zod
    db.ts                  MSSQL connection pool, decimal-safe type handling
  routes/
    health.ts               GET /api/health
    roles.ts                 GET /api/roles
  middleware/
    errorHandler.ts           centralized error handling, 404 handler
  utils/
    logger.ts                  Pino logger
    money.ts                    decimal-safe Money class for payroll math
```

## Notes for the real build

- `src/utils/money.ts` is the Money class discussed for payroll work — it
  has no public constructor from a raw number, so arithmetic can't
  accidentally touch a plain JS number. Every payslip amount calculation
  in Phase 2 should go through this class, not raw `+`/`-`/`*`.
- Authentication/RBAC middleware isn't built yet — that's Phase 1's first
  task, once the employee master schema and login flow are wired up.
- `getPool()` in `db.ts` is a lazy singleton — the first request that
  needs the database creates the connection pool; later requests reuse
  it. This is standard practice, not a bug.
