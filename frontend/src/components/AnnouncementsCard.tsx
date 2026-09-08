import { announcements } from "../data/mockData";
import "./AnnouncementsCard.css";

export default function AnnouncementsCard() {
  return (
    <div className="announcements-card">
      <p className="announcements-card__title">Announcements</p>
      <ul className="announcements-card__list">
        {announcements.map((item) => (
          <li key={item.id} className="announcements-card__item">
            <p className="announcements-card__item-title">{item.title}</p>
            <p className="announcements-card__item-date">{item.date}</p>
          </li>
        ))}
      </ul>
    </div>
  );
}
