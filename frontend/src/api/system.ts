import { apiFetch } from "./client";

export interface HealthResponse {
  status: string;
  database: string;
}

export interface Role {
  RoleCode: string;
  RoleName: string;
}

export function getHealth() {
  return apiFetch<HealthResponse>("/health");
}

export function getRoles() {
  return apiFetch<Role[]>("/roles");
}
