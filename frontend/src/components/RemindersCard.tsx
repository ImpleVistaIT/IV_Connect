import { FileText, CalendarClock, CheckCircle2, type LucideIcon } from "lucide-react";
import { reminders } from "../data/mockData";
import "./RemindersCard.css";

const ICONS: Record<string, LucideIcon> = {
  "file-text": FileText,
  "calendar-clock": CalendarClock,
  "check-circle": CheckCircle2,
};

export default function RemindersCard() {
  return (
    <div className="reminders-card">
      <p className="reminders-card__title">Reminders</p>

      <ul className="reminders-card__list">
        {reminders.map((item) => {
          const Icon = ICONS[item.icon];
          return (
            <li key={item.id} className="reminders-card__item">
              <span className={`reminders-card__icon reminders-card__icon--${item.tone}`}>
                <Icon size={15} strokeWidth={1.8} aria-hidden="true" />
              </span>
              <p>{item.text}</p>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
