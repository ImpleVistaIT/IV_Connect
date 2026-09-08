import { FileText, Download, Eye, Upload, BadgeCheck, GraduationCap } from "lucide-react";
import { employeeDocuments, type EmployeeDocument } from "../../data/mockData";
import { formatDate } from "../../utils/resumeCompliance";
import StatusBadge, { type BadgeTone } from "../StatusBadge";
import "./DocumentsTab.css";

const TONE_BY_STATUS: Record<EmployeeDocument["status"], BadgeTone> = {
  Verified: "success",
  "Pending review": "warning",
};

const CATEGORY_ICON = {
  Identity: BadgeCheck,
  Education: GraduationCap,
  Other: FileText,
};

function groupByCategory(docs: EmployeeDocument[]) {
  const groups: Record<string, EmployeeDocument[]> = {};
  for (const doc of docs) {
    groups[doc.category] = groups[doc.category] ?? [];
    groups[doc.category].push(doc);
  }
  return groups;
}

export default function DocumentsTab() {
  const groups = groupByCategory(employeeDocuments);

  return (
    <div className="documents-tab">
      {Object.entries(groups).map(([category, docs]) => {
        const CategoryIcon = CATEGORY_ICON[category as keyof typeof CATEGORY_ICON];
        return (
          <section className="documents-tab__section" key={category}>
            <p className="documents-tab__section-title">
              <CategoryIcon size={16} strokeWidth={1.8} aria-hidden="true" />
              {category} documents
            </p>

            <div className="documents-tab__list">
              {docs.map((doc) => (
                <div className="document-row" key={doc.id}>
                  <div className="document-row__icon">
                    <FileText size={17} strokeWidth={1.8} aria-hidden="true" />
                  </div>
                  <div className="document-row__info">
                    <p className="document-row__name">{doc.name}</p>
                    <p className="document-row__meta">
                      {doc.fileName} &middot; uploaded {formatDate(doc.uploadedOn)}
                    </p>
                  </div>
                  <StatusBadge label={doc.status} tone={TONE_BY_STATUS[doc.status]} />
                  <div className="document-row__actions">
                    <button className="document-row__action" aria-label={`View ${doc.name}`}>
                      <Eye size={15} strokeWidth={1.8} />
                    </button>
                    <button className="document-row__action" aria-label={`Download ${doc.name}`}>
                      <Download size={15} strokeWidth={1.8} />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </section>
        );
      })}

      <section className="documents-tab__section">
        <p className="documents-tab__section-title">Add a document</p>
        <label className="documents-tab__upload" htmlFor="doc-upload">
          <Upload size={16} strokeWidth={1.8} aria-hidden="true" />
          <span>Upload a scanned copy — PDF or image, up to 10 MB</span>
        </label>
        <input id="doc-upload" type="file" className="documents-tab__upload-hidden" />
      </section>
    </div>
  );
}
