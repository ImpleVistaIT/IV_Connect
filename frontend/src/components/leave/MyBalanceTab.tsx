import { leaveBalanceDetailed } from "../../data/mockData";
import "./MyBalanceTab.css";

export default function MyBalanceTab() {
  const totalBalance = leaveBalanceDetailed.reduce((sum, row) => sum + row.balance, 0);

  return (
    <div className="balance-tab">
      <div className="balance-tab__cards">
        {leaveBalanceDetailed.map((row) => (
          <div className="balance-tab__card" key={row.code}>
            <p className="balance-tab__card-label">{row.name}</p>
            <p className="balance-tab__card-value">{row.balance}</p>
            <div className="balance-tab__card-bar">
              <div
                className="balance-tab__card-bar-fill"
                style={{
                  width: row.annualQuota > 0 ? `${Math.min((row.used / row.annualQuota) * 100, 100)}%` : "0%",
                }}
              />
            </div>
            <p className="balance-tab__card-footnote">
              {row.used} used of {row.annualQuota || "\u2014"}
            </p>
          </div>
        ))}
      </div>

      <div className="balance-tab__table-card">
        <div className="balance-tab__table-header">
          <p className="balance-tab__table-title">Balance detail</p>
          <p className="balance-tab__table-total">{totalBalance} days total</p>
        </div>
        <table className="balance-table">
          <thead>
            <tr>
              <th>Leave type</th>
              <th>Annual quota</th>
              <th>Accrued to date</th>
              <th>Used</th>
              <th>Carry forward</th>
              <th>Balance</th>
            </tr>
          </thead>
          <tbody>
            {leaveBalanceDetailed.map((row) => (
              <tr key={row.code}>
                <td className="balance-table__type">{row.name}</td>
                <td>{row.annualQuota || "\u2014"}</td>
                <td>{row.accrued}</td>
                <td>{row.used}</td>
                <td>{row.carryForward || "\u2014"}</td>
                <td className="balance-table__balance">{row.balance}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <p className="balance-tab__note">
          Balance is calculated from an append-only ledger of accruals, approvals and carry-forward
          entries — every change is traceable, not just the running total.
        </p>
      </div>
    </div>
  );
}
