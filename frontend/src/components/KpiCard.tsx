import { type LucideIcon } from "lucide-react";
import "./KpiCard.css";

type Tone = "brand" | "success" | "warning" | "danger" | "neutral";

interface KpiCardProps {
  icon: LucideIcon;
  label: string;
  value: string;
  unit?: string;
  tone?: Tone;
  footnote?: string;
}

export default function KpiCard({
  icon: Icon,
  label,
  value,
  unit,
  tone = "neutral",
  footnote,
}: KpiCardProps) {
  return (
    <div className="kpi-card">
      <div className={`kpi-card__icon kpi-card__icon--${tone}`}>
        <Icon size={18} strokeWidth={1.8} aria-hidden="true" />
      </div>
      <p className="kpi-card__label">{label}</p>
      <p className="kpi-card__value">
        {value}
        {unit && <span className="kpi-card__unit">{unit}</span>}
      </p>
      {footnote && <p className="kpi-card__footnote">{footnote}</p>}
    </div>
  );
}
