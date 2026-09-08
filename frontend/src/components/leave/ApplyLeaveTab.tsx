import { useMemo, useState } from "react";
import { Paperclip } from "lucide-react";
import { leaveTypes } from "../../data/mockData";
import "./ApplyLeaveTab.css";

function daysBetween(from: string, to: string): number {
  if (!from || !to) return 0;
  const msPerDay = 1000 * 60 * 60 * 24;
  const diff = (new Date(to).getTime() - new Date(from).getTime()) / msPerDay;
  return diff >= 0 ? diff + 1 : 0;
}

export default function ApplyLeaveTab() {
  const [typeCode, setTypeCode] = useState(leaveTypes[0].code);
  const [fromDate, setFromDate] = useState("");
  const [toDate, setToDate] = useState("");
  const [halfDay, setHalfDay] = useState(false);
  const [reason, setReason] = useState("");
  const [attachment, setAttachment] = useState<string | null>(null);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitted, setSubmitted] = useState(false);

  const selectedType = leaveTypes.find((t) => t.code === typeCode)!;
  const rawDays = daysBetween(fromDate, toDate);
  const totalDays = halfDay ? 0.5 : rawDays;

  const attachmentRequired = useMemo(() => {
    if (!selectedType.attachmentRequiredAfterDays) return false;
    return rawDays > selectedType.attachmentRequiredAfterDays;
  }, [selectedType, rawDays]);

  function validate(): boolean {
    const next: Record<string, string> = {};
    if (!fromDate) next.fromDate = "Select a start date";
    if (!halfDay && !toDate) next.toDate = "Select an end date";
    if (!halfDay && fromDate && toDate && new Date(toDate) < new Date(fromDate)) {
      next.toDate = "End date can't be before start date";
    }
    if (!reason.trim()) next.reason = "Enter a reason";
    if (attachmentRequired && !attachment) {
      next.attachment = `Attach a document — required for ${selectedType.name} beyond ${selectedType.attachmentRequiredAfterDays} days`;
    }
    setErrors(next);
    return Object.keys(next).length === 0;
  }

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!validate()) {
      setSubmitted(false);
      return;
    }
    setSubmitted(true);
  }

  return (
    <div className="apply-leave">
      <form className="apply-leave__form" onSubmit={handleSubmit} noValidate>
        <div className="apply-leave__row">
          <div className="apply-leave__field">
            <label htmlFor="leaveType">Leave type</label>
            <select
              id="leaveType"
              value={typeCode}
              onChange={(e) => {
                setTypeCode(e.target.value);
                setSubmitted(false);
              }}
            >
              {leaveTypes.map((t) => (
                <option key={t.code} value={t.code}>
                  {t.name} {t.isPaid ? "" : "(unpaid)"}
                </option>
              ))}
            </select>
          </div>

          <div className="apply-leave__field apply-leave__field--checkbox">
            <label className="apply-leave__checkbox-label">
              <input
                type="checkbox"
                checked={halfDay}
                disabled={!selectedType.allowHalfDay}
                onChange={(e) => setHalfDay(e.target.checked)}
              />
              Half day
            </label>
          </div>
        </div>

        <div className="apply-leave__row">
          <div className="apply-leave__field">
            <label htmlFor="fromDate">From date</label>
            <input
              id="fromDate"
              type="date"
              value={fromDate}
              onChange={(e) => setFromDate(e.target.value)}
            />
            {errors.fromDate && <p className="apply-leave__error">{errors.fromDate}</p>}
          </div>

          <div className="apply-leave__field">
            <label htmlFor="toDate">To date</label>
            <input
              id="toDate"
              type="date"
              value={halfDay ? fromDate : toDate}
              disabled={halfDay}
              onChange={(e) => setToDate(e.target.value)}
            />
            {errors.toDate && <p className="apply-leave__error">{errors.toDate}</p>}
          </div>
        </div>

        <div className="apply-leave__field">
          <label htmlFor="reason">Reason</label>
          <textarea
            id="reason"
            rows={3}
            placeholder="Briefly describe the reason for leave"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
          />
          {errors.reason && <p className="apply-leave__error">{errors.reason}</p>}
        </div>

        {selectedType.attachmentRequiredAfterDays !== null && (
          <div className="apply-leave__field">
            <label htmlFor="attachment">
              Attachment {attachmentRequired ? "(required)" : "(optional)"}
            </label>
            <label className="apply-leave__file-input" htmlFor="attachment">
              <Paperclip size={15} strokeWidth={1.8} aria-hidden="true" />
              <span>{attachment ?? "Choose a file — medical certificate, proof, etc."}</span>
            </label>
            <input
              id="attachment"
              type="file"
              className="apply-leave__file-hidden"
              onChange={(e) => setAttachment(e.target.files?.[0]?.name ?? null)}
            />
            {errors.attachment && <p className="apply-leave__error">{errors.attachment}</p>}
          </div>
        )}

        {totalDays > 0 && (
          <p className="apply-leave__summary-text">
            This request is for {totalDays} day{totalDays !== 1 ? "s" : ""}.
          </p>
        )}

        {submitted && (
          <div className="apply-leave__confirmation">
            Leave request submitted. You'll be notified once your manager reviews it.
          </div>
        )}

        <div className="apply-leave__actions">
          <button type="submit" className="apply-leave__submit">
            Submit request
          </button>
        </div>
      </form>
    </div>
  );
}
