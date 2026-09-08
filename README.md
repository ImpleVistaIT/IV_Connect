# IVConnect

Employee portal monorepo: a React + TypeScript + Vite frontend, an Express + TypeScript + MSSQL backend, and the SQL Server baseline/migration scripts that back them.

```
ivconnect/
├── frontend/     React + Vite employee portal UI
├── backend/      Express API (health, roles, ...) backed by MSSQL
├── database/
│   ├── baseline/     initial schema (IVConnect_baseline.sql)
│   └── migrations/   incremental schema changes (empty for now)
└── docs/
```

## Running locally

Two terminals, both projects run independently:

```bash
# backend — http://localhost:4000
cd backend
npm install
cp .env.example .env   # fill in your local MSSQL credentials
npm run dev

# frontend — http://localhost:5173
cd frontend
npm install
cp .env.example .env   # VITE_API_BASE_URL=http://localhost:4000/api
npm run dev
```

The frontend calls the backend's `/api/health` and `/api/roles` endpoints; `/api/roles` only returns real data once the baseline SQL script in `database/baseline/` has been applied to your local database.

See [frontend/README.md](frontend/README.md) and [backend/README.md](backend/README.md) for project-specific details.
