import { useState } from "react";
import { Eye, EyeOff } from "lucide-react";
import { employeeProfile } from "../../data/mockData";
import { formatDate } from "../../utils/resumeCompliance";
import "./ProfileDetailsTab.css";

const FULL_PAN = "ABCDE1234Z";

function InfoRow({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="info-row">
      <p className="info-row__label">{label}</p>
      <p className="info-row__value">{value}</p>
    </div>
  );
}

export default function ProfileDetailsTab() {
  const [panRevealed, setPanRevealed] = useState(false);

  return (
    <div className="profile-details">
      <section className="profile-details__section">
        <p className="profile-details__section-title">Employment</p>
        <div className="profile-details__grid">
          <InfoRow label="Employee ID" value={employeeProfile.employeeCode} />
          <InfoRow label="Designation" value={employeeProfile.designation} />
          <InfoRow label="Department" value={employeeProfile.department} />
          <InfoRow label="Grade" value={employeeProfile.gradeLevel} />
          <InfoRow
            label="Reporting manager"
            value={`${employeeProfile.manager.name} (${employeeProfile.manager.code})`}
          />
          <InfoRow label="Date of joining" value={formatDate(employeeProfile.dateOfJoining)} />
          <InfoRow label="Employment status" value={employeeProfile.employmentStatus} />
        </div>
      </section>

      <section className="profile-details__section">
        <p className="profile-details__section-title">Contact</p>
        <div className="profile-details__grid">
          <InfoRow label="Work email" value={employeeProfile.email} />
          <InfoRow label="Contact number" value={employeeProfile.contactNumber} />
          <InfoRow label="Address" value={employeeProfile.address} />
        </div>
      </section>

      <section className="profile-details__section">
        <p className="profile-details__section-title">Personal</p>
        <div className="profile-details__grid">
          <InfoRow label="Date of birth" value={formatDate(employeeProfile.dateOfBirth)} />
          <InfoRow label="Blood group" value={employeeProfile.bloodGroup} />
          <InfoRow
            label="PAN"
            value={
              <span className="profile-details__pan">
                <span className="profile-details__pan-value">
                  {panRevealed ? FULL_PAN : employeeProfile.pan}
                </span>
                <button
                  className="profile-details__pan-toggle"
                  onClick={() => setPanRevealed((v) => !v)}
                  aria-label={panRevealed ? "Hide PAN" : "Reveal PAN"}
                  type="button"
                >
                  {panRevealed ? (
                    <EyeOff size={14} strokeWidth={1.8} />
                  ) : (
                    <Eye size={14} strokeWidth={1.8} />
                  )}
                </button>
              </span>
            }
          />
        </div>
        {panRevealed && (
          <p className="profile-details__audit-note">
            This reveal has been logged for audit, in line with PAN access policy.
          </p>
        )}
      </section>
    </div>
  );
}
