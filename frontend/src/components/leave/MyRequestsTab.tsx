import { X } from "lucide-react";
import { leaveRequests } from "../../data/mockData";
import { formatDate } from "../../utils/resumeCompliance";
import StatusBadge, { type BadgeTone } from "../StatusBadge";
import "./MyRequestsTab.css";

const TONE_BY_STATUS: Record<string, BadgeTone> = {
  Pending: "warning",
  Approved: "success",
  Rejected: "danger",
  Cancelled: "neutral",
};

export default function MyRequestsTab() {
  return (
    <div className="requests-card">
      <table className="requests-table">
        <thead>
          <tr>
            <th>Applied on</th>
            <th>Type</th>
            <th>Dates</th>
            <th>Days</th>
            <th>Reason</th>
            <th>Approver</th>
            <th>Status</th>
            <th aria-label="Actions" />
          </tr>
        </thead>
        <tbody>
          {leaveRequests.map((req) => (
            <tr key={req.id}>
              <td className="requests-table__muted">{formatDate(req.appliedOn)}</td>
              <td className="requests-table__type">{req.leaveType}</td>
              <td className="requests-table__muted">
                {req.fromDate === req.toDate
                  ? formatDate(req.fromDate)
                  : `${formatDate(req.fromDate)} – ${formatDate(req.toDate)}`}
              </td>
              <td>{req.days}</td>
              <td className="requests-table__reason" title={req.reason}>
                {req.reason}
              </td>
              <td className="requests-table__muted">{req.approver}</td>
              <td>
                <StatusBadge label={req.status} tone={TONE_BY_STATUS[req.status]} />
              </td>
              <td>
                {req.status === "Pending" && (
                  <button className="requests-table__cancel" aria-label={`Cancel request ${req.id}`}>
                    <X size={14} strokeWidth={2} />
                  </button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
