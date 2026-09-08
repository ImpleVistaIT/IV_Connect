import { useState } from "react";
import { currentEmployee } from "../data/mockData";
import PillTabs from "../components/PillTabs";
import ProfileDetailsTab from "../components/profile/ProfileDetailsTab";
import DocumentsTab from "../components/profile/DocumentsTab";
import "./ProfilePage.css";

const TABS = ["Profile details", "Documents"];

export default function ProfilePage() {
  const [activeTab, setActiveTab] = useState(TABS[0]);

  return (
    <main className="profile-page scrollbar-thin">
      <div className="profile-page__intro">
        <div className="profile-page__avatar">{currentEmployee.initials}</div>
        <div>
          <h1 className="profile-page__name">{currentEmployee.fullName}</h1>
          <p className="profile-page__subtitle">
            {currentEmployee.employeeCode} &middot; {currentEmployee.designation}
          </p>
        </div>
      </div>

      <PillTabs tabs={TABS} active={activeTab} onChange={setActiveTab} />

      {activeTab === "Profile details" && <ProfileDetailsTab />}
      {activeTab === "Documents" && <DocumentsTab />}
    </main>
  );
}
