import { FileEdit } from "lucide-react";
import { resumeStatus } from "../data/mockData";
import { getResumeComplianceState, formatDate } from "../utils/resumeCompliance";
import StatusBadge, { type BadgeTone } from "./StatusBadge";
import "./ResumeStatusCard.css";

const TONE_BY_STATE: Record<string, BadgeTone> = {
  Compliant: "success",
  "Due soon": "warning",
  Overdue: "danger",
};

export default function ResumeStatusCard() {
  const { state, daysSince } = getResumeComplianceState(resumeStatus.lastUpdated);

  return (
    <div className="resume-card">
      <div className="resume-card__row">
        <div className="resume-card__icon">
          <FileEdit size={17} strokeWidth={1.8} aria-hidden="true" />
        </div>
        <div>
          <p className="resume-card__title">Resume status</p>
          <StatusBadge label={state} tone={TONE_BY_STATE[state]} />
        </div>
        <button className="resume-card__cta">Update</button>
      </div>
      <div className="resume-card__meta">
        <span>
          Last updated {formatDate(resumeStatus.lastUpdated)} &middot; {daysSince} days ago
        </span>
        <span>Next due {formatDate(resumeStatus.nextDue)}</span>
      </div>
    </div>
  );
}
