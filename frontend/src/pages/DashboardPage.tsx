import { CalendarDays, FileText, FileEdit, Clock } from "lucide-react";
import { currentEmployee, leaveRequests, resumeStatus } from "../data/mockData";
import { getResumeComplianceState } from "../utils/resumeCompliance";
import KpiCard from "../components/KpiCard";
import LeaveBalanceCard from "../components/LeaveBalanceCard";
import PayslipTable from "../components/PayslipTable";
import RemindersCard from "../components/RemindersCard";
import ResumeStatusCard from "../components/ResumeStatusCard";
import AnnouncementsCard from "../components/AnnouncementsCard";
import "./DashboardPage.css";

const KPI_TONE_BY_STATE = {
  Compliant: "success",
  "Due soon": "warning",
  Overdue: "danger",
} as const;

export default function DashboardPage() {
  const pendingCount = leaveRequests.filter((r) => r.status === "Pending").length;
  const resume = getResumeComplianceState(resumeStatus.lastUpdated);

  return (
    <main className="dashboard scrollbar-thin">
      <div className="dashboard__intro">
        <h1 className="dashboard__greeting">
          Good morning, {currentEmployee.fullName.split(" ")[0]}
        </h1>
        <p className="dashboard__subtitle">Here's what's on your desk today.</p>
      </div>

      <RemindersCard />

      <div className="dashboard__kpi-row">
        <KpiCard icon={CalendarDays} label="Leave balance" value="14.5" unit="days" tone="brand" />
        <KpiCard icon={FileText} label="Latest payslip" value="Aug 2026" tone="neutral" footnote="Ready to download" />
        <KpiCard
          icon={FileEdit}
          label="Resume status"
          value={resume.state}
          tone={KPI_TONE_BY_STATE[resume.state]}
          footnote={`${resume.daysSince} days since update`}
        />
        <KpiCard icon={Clock} label="Leave requests" value={String(pendingCount)} unit="pending" tone="warning" />
      </div>

      <div className="dashboard__grid">
        <div className="dashboard__col dashboard__col--main">
          <PayslipTable />
          <ResumeStatusCard />
        </div>
        <div className="dashboard__col dashboard__col--side">
          <LeaveBalanceCard />
          <AnnouncementsCard />
        </div>
      </div>
    </main>
  );
}
