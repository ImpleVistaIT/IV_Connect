import { Router } from "express";
import { getPool } from "../config/db.js";

export const healthRouter = Router();

healthRouter.get("/health", async (req, res, next) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query("SELECT 1 AS ok");
    res.json({
      status: "ok",
      database: result.recordset[0]?.ok === 1 ? "connected" : "unknown",
    });
  } catch (err) {
    next(err);
  }
});
