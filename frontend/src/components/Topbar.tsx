import { Search, Bell } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { currentEmployee } from "../data/mockData";
import ConnectionStatus from "./ConnectionStatus";
import "./Topbar.css";

export default function Topbar() {
  const navigate = useNavigate();

  return (
    <header className="topbar">
      <div className="topbar__search">
        <Search size={16} strokeWidth={1.8} aria-hidden="true" />
        <input type="text" placeholder="Search employees, payslips, leave" />
      </div>

      <div className="topbar__actions">
        <ConnectionStatus />

        <button className="topbar__icon-btn" aria-label="Notifications">
          <Bell size={18} strokeWidth={1.8} />
          <span className="topbar__badge" aria-hidden="true" />
        </button>

        <div className="topbar__divider" />

        <button className="topbar__profile" onClick={() => navigate("/profile")} aria-label="View my profile">
          <div className="topbar__avatar">{currentEmployee.initials}</div>
          <div className="topbar__profile-text">
            <p className="topbar__name">{currentEmployee.fullName}</p>
            <p className="topbar__meta">
              {currentEmployee.employeeCode} &middot; {currentEmployee.designation}
            </p>
          </div>
        </button>
      </div>
    </header>
  );
}
