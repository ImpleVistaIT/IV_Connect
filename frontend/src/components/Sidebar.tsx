import { NavLink } from "react-router-dom";
import {
  LayoutDashboard,
  User,
  FileText,
  FileEdit,
  CalendarDays,
  Settings,
  LogOut,
} from "lucide-react";
import "./Sidebar.css";

const NAV_ITEMS = [
  { label: "Dashboard", to: "/", icon: LayoutDashboard },
  { label: "My profile", to: "/profile", icon: User },
  { label: "Payslips", to: "/payslips", icon: FileText },
  { label: "Resume", to: "/resume", icon: FileEdit },
  { label: "Leave", to: "/leave", icon: CalendarDays },
];

export default function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="sidebar__brand">
        <div className="sidebar__logo">IV</div>
        <span className="sidebar__brand-name">IVConnect</span>
      </div>

      <nav className="sidebar__nav" aria-label="Primary">
        {NAV_ITEMS.map(({ label, to, icon: Icon }) => (
          <NavLink
            key={label}
            to={to}
            end={to === "/"}
            className={({ isActive }) =>
              isActive ? "sidebar__item sidebar__item--active" : "sidebar__item"
            }
          >
            <Icon size={18} strokeWidth={1.8} aria-hidden="true" />
            <span>{label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar__footer">
        <button className="sidebar__item">
          <Settings size={18} strokeWidth={1.8} aria-hidden="true" />
          <span>Settings</span>
        </button>
        <button className="sidebar__item">
          <LogOut size={18} strokeWidth={1.8} aria-hidden="true" />
          <span>Sign out</span>
        </button>
      </div>
    </aside>
  );
}
