import { useState } from "react";
import { CalendarDays } from "lucide-react";
import { holidayCalendarNote } from "../data/mockData";
import PillTabs from "../components/PillTabs";
import ApplyLeaveTab from "../components/leave/ApplyLeaveTab";
import MyRequestsTab from "../components/leave/MyRequestsTab";
import MyBalanceTab from "../components/leave/MyBalanceTab";
import "./LeavePage.css";

const TABS = ["Apply for leave", "My requests", "My balance"];

export default function LeavePage() {
  const [activeTab, setActiveTab] = useState(TABS[0]);

  return (
    <main className="leave-page scrollbar-thin">
      <div className="leave-page__intro">
        <div>
          <h1 className="leave-page__title">Leave</h1>
          <p className="leave-page__subtitle">Apply for leave, track requests and check your balance.</p>
        </div>
        <div className="leave-page__holiday-note">
          <CalendarDays size={15} strokeWidth={1.8} aria-hidden="true" />
          <span>{holidayCalendarNote}</span>
        </div>
      </div>

      <PillTabs tabs={TABS} active={activeTab} onChange={setActiveTab} />

      {activeTab === "Apply for leave" && <ApplyLeaveTab />}
      {activeTab === "My requests" && <MyRequestsTab />}
      {activeTab === "My balance" && <MyBalanceTab />}
    </main>
  );
}
