import "./StatusBadge.css";

export type BadgeTone = "success" | "warning" | "danger" | "neutral" | "brand";

interface StatusBadgeProps {
  label: string;
  tone: BadgeTone;
}

export default function StatusBadge({ label, tone }: StatusBadgeProps) {
  return <span className={`status-badge status-badge--${tone}`}>{label}</span>;
}
