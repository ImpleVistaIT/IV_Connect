import { useState } from "react";
import { Download, Eye, EyeOff } from "lucide-react";
import {
  payslipRecords,
  getGrossPay,
  getNetPay,
  getTotalDeductions,
  currentEmployee,
} from "../data/mockData";
import StatusBadge, { type BadgeTone } from "../components/StatusBadge";
import "./PayslipsPage.css";

const STATUS_TONE: Record<string, BadgeTone> = {
  Available: "success",
  Processing: "warning",
};

const formatCurrency = (value: number) => `\u20B9${value.toLocaleString("en-IN")}`;

export default function PayslipsPage() {
  const [visiblePeriods, setVisiblePeriods] = useState<Set<string>>(new Set());

  const toggleVisibility = (period: string) => {
    setVisiblePeriods((prev) => {
      const next = new Set(prev);
      next.has(period) ? next.delete(period) : next.add(period);
      return next;
    });
  };

  const latest = payslipRecords[0];
  const ytdGross = payslipRecords.reduce((sum, row) => sum + getGrossPay(row), 0);
  const ytdDeductions = payslipRecords.reduce((sum, row) => sum + getTotalDeductions(row), 0);

  return (
    <main className="payslips-page scrollbar-thin">
      <div className="payslips-page__intro">
        <h1 className="payslips-page__title">Payslips</h1>
        <p className="payslips-page__subtitle">
          Monthly pay statements for {currentEmployee.fullName} · {currentEmployee.employeeCode}
        </p>
      </div>

      <div className="payslips-page__summary">
        <div className="payslips-summary-card">
          <p className="payslips-summary-card__label">Latest net pay</p>
          <p className="payslips-summary-card__value">{formatCurrency(getNetPay(latest))}</p>
          <p className="payslips-summary-card__footnote">{latest.period}</p>
        </div>
        <div className="payslips-summary-card">
          <p className="payslips-summary-card__label">Gross pay (last {payslipRecords.length} months)</p>
          <p className="payslips-summary-card__value">{formatCurrency(ytdGross)}</p>
        </div>
        <div className="payslips-summary-card">
          <p className="payslips-summary-card__label">Deductions (last {payslipRecords.length} months)</p>
          <p className="payslips-summary-card__value">{formatCurrency(ytdDeductions)}</p>
        </div>
      </div>

      <div className="payslips-table-card">
        <table className="payslips-table">
          <thead>
            <tr>
              <th>Period</th>
              <th>Pay date</th>
              <th>Working days</th>
              <th>Gross pay</th>
              <th>Deductions</th>
              <th>Net pay</th>
              <th>Status</th>
              <th aria-label="Download" />
            </tr>
          </thead>
          <tbody>
            {payslipRecords.map((row) => {
              const isVisible = visiblePeriods.has(row.period);
              return (
                <tr key={row.period}>
                  <td className="payslips-table__period">{row.period}</td>
                  <td className="payslips-table__muted">
                    {new Date(row.payDate).toLocaleDateString("en-IN", { day: "2-digit", month: "short", year: "numeric" })}
                  </td>
                  <td className="payslips-table__muted">
                    {row.workingDays}
                    {row.lopDays > 0 && <span className="payslips-table__lop"> ({row.lopDays} LOP)</span>}
                  </td>
                  <td className="payslips-table__amount">{formatCurrency(getGrossPay(row))}</td>
                  <td className="payslips-table__amount">{formatCurrency(getTotalDeductions(row))}</td>
                  <td className="payslips-table__amount">
                    <span className="payslips-table__amount-value">
                      {isVisible ? formatCurrency(getNetPay(row)) : "\u2022\u2022\u2022\u2022\u2022\u2022"}
                    </span>
                    <button
                      className="payslips-table__reveal"
                      onClick={() => toggleVisibility(row.period)}
                      aria-label={isVisible ? `Hide ${row.period} net pay` : `Show ${row.period} net pay`}
                      aria-pressed={isVisible}
                    >
                      {isVisible ? <EyeOff size={14} strokeWidth={1.8} /> : <Eye size={14} strokeWidth={1.8} />}
                    </button>
                  </td>
                  <td>
                    <StatusBadge label={row.status} tone={STATUS_TONE[row.status]} />
                  </td>
                  <td>
                    <button className="payslips-table__download" aria-label={`Download ${row.period} payslip`}>
                      <Download size={15} strokeWidth={1.8} />
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </main>
  );
}
