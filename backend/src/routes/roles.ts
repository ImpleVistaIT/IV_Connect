import { Router } from "express";
import { getPool } from "../config/db.js";

export const rolesRouter = Router();

// The same 7 roles you queried directly in your SQL client - this proves
// the Node app can read the same data through the API layer, not just
// through a database tool.
rolesRouter.get("/roles", async (req, res, next) => {
  try {
    const pool = await getPool();
    const result = await pool
      .request()
      .query("SELECT RoleCode, RoleName FROM core.Roles ORDER BY RoleId");
    res.json(result.recordset);
  } catch (err) {
    next(err);
  }
});
