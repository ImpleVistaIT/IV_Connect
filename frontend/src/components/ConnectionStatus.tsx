import { useEffect, useState } from "react";
import { getHealth } from "../api/system";
import "./ConnectionStatus.css";

const POLL_INTERVAL_MS = 15000;

export default function ConnectionStatus() {
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    let cancelled = false;

    const check = async () => {
      try {
        await getHealth();
        if (!cancelled) setConnected(true);
      } catch {
        if (!cancelled) setConnected(false);
      }
    };

    check();
    const timer = setInterval(check, POLL_INTERVAL_MS);
    return () => {
      cancelled = true;
      clearInterval(timer);
    };
  }, []);

  return (
    <div className="connection-status" role="status">
      <span
        className={`connection-status__dot ${connected ? "connection-status__dot--online" : "connection-status__dot--offline"}`}
        aria-hidden="true"
      />
      <span className="connection-status__label">{connected ? "Backend connected" : "Backend offline"}</span>
    </div>
  );
}
