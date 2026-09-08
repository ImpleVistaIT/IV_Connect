import { leaveBalance } from "../data/mockData";
import "./LeaveBalanceCard.css";

export default function LeaveBalanceCard() {
  const total = leaveBalance.breakdown.reduce((sum, item) => sum + item.days, 0);

  return (
    <div className="leave-card">
      <div className="leave-card__header">
        <p className="leave-card__title">Leave balance</p>
        <button className="leave-card__link">Apply for leave</button>
      </div>

      <p className="leave-card__total">
        {leaveBalance.totalDays}
        <span> days available</span>
      </p>

      <div className="leave-card__bar" role="img" aria-label="Leave balance breakdown by type">
        {leaveBalance.breakdown.map((item) => (
          <div
            key={item.code}
            className="leave-card__bar-segment"
            style={{
              width: `${(item.days / total) * 100}%`,
              background: item.color,
            }}
          />
        ))}
      </div>

      <div className="leave-card__legend">
        {leaveBalance.breakdown.map((item) => (
          <div className="leave-card__legend-item" key={item.code}>
            <span className="leave-card__dot" style={{ background: item.color }} />
            <span className="leave-card__legend-label">{item.label}</span>
            <span className="leave-card__legend-value">{item.days}d</span>
          </div>
        ))}
      </div>
    </div>
  );
}
