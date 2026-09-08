import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Download, Eye, EyeOff } from "lucide-react";
import { payslips } from "../data/mockData";
import "./PayslipTable.css";

export default function PayslipTable() {
  const navigate = useNavigate();
  const [visiblePeriods, setVisiblePeriods] = useState<Set<string>>(new Set());

  const toggleVisibility = (period: string) => {
    setVisiblePeriods((prev) => {
      const next = new Set(prev);
      if (next.has(period)) {
        next.delete(period);
      } else {
        next.add(period);
      }
      return next;
    });
  };

  return (
    <div className="payslip-card">
      <div className="payslip-card__header">
        <p className="payslip-card__title">Recent payslips</p>
        <button className="payslip-card__link" onClick={() => navigate("/payslips")}>
          View all
        </button>
      </div>

      <table className="payslip-table">
        <thead>
          <tr>
            <th>Period</th>
            <th>Net pay</th>
            <th>Status</th>
            <th aria-label="Download" />
          </tr>
        </thead>
        <tbody>
          {payslips.map((row) => {
            const isVisible = visiblePeriods.has(row.period);
            return (
              <tr key={row.period}>
                <td className="payslip-table__period">{row.period}</td>
                <td className="payslip-table__amount">
                  <span className="payslip-table__amount-value">
                    {isVisible ? <>&#8377;{row.netPay}</> : "••••••"}
                  </span>
                  <button
                    className="payslip-table__reveal"
                    onClick={() => toggleVisibility(row.period)}
                    aria-label={isVisible ? `Hide ${row.period} net pay` : `Show ${row.period} net pay`}
                    aria-pressed={isVisible}
                  >
                    {isVisible ? <EyeOff size={14} strokeWidth={1.8} /> : <Eye size={14} strokeWidth={1.8} />}
                  </button>
                </td>
                <td>
                  <span className="payslip-table__status">{row.status}</span>
                </td>
                <td>
                  <button className="payslip-table__download" aria-label={`Download ${row.period} payslip`}>
                    <Download size={15} strokeWidth={1.8} />
                  </button>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
