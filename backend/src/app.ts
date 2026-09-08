import express from "express";
import cors from "cors";
import helmet from "helmet";
import { pinoHttp } from "pino-http";
import { logger } from "./utils/logger.js";
import { healthRouter } from "./routes/health.js";
import { rolesRouter } from "./routes/roles.js";
import { notFoundHandler, errorHandler } from "./middleware/errorHandler.js";

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(pinoHttp({ logger }));

app.use("/api", healthRouter);
app.use("/api", rolesRouter);

app.use(notFoundHandler);
app.use(errorHandler);
