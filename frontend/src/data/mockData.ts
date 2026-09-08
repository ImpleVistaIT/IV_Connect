// ---------------------------------------------------------------------------
// Placeholder data, shaped the way the real /api/v1/me/* endpoints would
// return it. Swap this module out once the backend exists.
// ---------------------------------------------------------------------------

export const currentEmployee = {
  fullName: "Naga Yashas",
  employeeCode: "IVB036",
  designation: "Senior Software Engineer",
  department: "Web & Application Development",
  initials: "NY",
};

// -------------------- Dashboard --------------------

export const leaveBalance = {
  totalDays: 14.5,
  breakdown: [
    { code: "EL", label: "Earned leave", days: 8.5, color: "var(--teal-500)" },
    { code: "CL", label: "Casual leave", days: 4, color: "var(--teal-300)" },
    { code: "SL", label: "Sick leave", days: 2, color: "var(--grey-300)" },
  ],
};

export interface PayslipRecord {
  period: string;
  payDate: string;
  status: "Available" | "Processing";
  workingDays: number;
  lopDays: number;
  earnings: {
    basic: number;
    hra: number;
    specialAllowance: number;
    bonus: number;
  };
  deductions: {
    providentFund: number;
    professionalTax: number;
    incomeTax: number;
  };
}

export const payslipRecords: PayslipRecord[] = [
  {
    period: "August 2026",
    payDate: "2026-08-31",
    status: "Available",
    workingDays: 21,
    lopDays: 0,
    earnings: { basic: 42000, hra: 16800, specialAllowance: 12200, bonus: 0 },
    deductions: { providentFund: 5040, professionalTax: 200, incomeTax: 3360 },
  },
  {
    period: "July 2026",
    payDate: "2026-07-31",
    status: "Available",
    workingDays: 23,
    lopDays: 0,
    earnings: { basic: 42000, hra: 16800, specialAllowance: 12200, bonus: 0 },
    deductions: { providentFund: 5040, professionalTax: 200, incomeTax: 3360 },
  },
  {
    period: "June 2026",
    payDate: "2026-06-30",
    status: "Available",
    workingDays: 20,
    lopDays: 1,
    earnings: { basic: 42000, hra: 16800, specialAllowance: 11700, bonus: 0 },
    deductions: { providentFund: 5040, professionalTax: 200, incomeTax: 3260 },
  },
  {
    period: "May 2026",
    payDate: "2026-05-31",
    status: "Available",
    workingDays: 21,
    lopDays: 0,
    earnings: { basic: 41000, hra: 16400, specialAllowance: 11500, bonus: 5000 },
    deductions: { providentFund: 4920, professionalTax: 200, incomeTax: 3540 },
  },
];

function grossPay(row: PayslipRecord) {
  const { basic, hra, specialAllowance, bonus } = row.earnings;
  return basic + hra + specialAllowance + bonus;
}

function totalDeductions(row: PayslipRecord) {
  const { providentFund, professionalTax, incomeTax } = row.deductions;
  return providentFund + professionalTax + incomeTax;
}

export function getNetPay(row: PayslipRecord) {
  return grossPay(row) - totalDeductions(row);
}

export function getGrossPay(row: PayslipRecord) {
  return grossPay(row);
}

export function getTotalDeductions(row: PayslipRecord) {
  return totalDeductions(row);
}

export const payslips = payslipRecords.map((row) => ({
  period: row.period,
  netPay: getNetPay(row).toLocaleString("en-IN"),
  status: row.status,
}));


export const resumeStatus = {
  lastUpdated: "2026-08-03",
  nextDue: "2026-09-25",
};

export const leaveRequests = [
  {
    id: "LR-1042",
    appliedOn: "2026-08-28",
    leaveType: "Casual leave",
    fromDate: "2026-09-08",
    toDate: "2026-09-08",
    days: 1,
    halfDay: false,
    reason: "Personal work",
    status: "Pending" as const,
    approver: "Meera Iyer",
  },
  {
    id: "LR-1031",
    appliedOn: "2026-08-10",
    leaveType: "Sick leave",
    fromDate: "2026-08-12",
    toDate: "2026-08-13",
    days: 2,
    halfDay: false,
    reason: "Fever, viral infection",
    status: "Approved" as const,
    approver: "Meera Iyer",
  },
  {
    id: "LR-0987",
    appliedOn: "2026-07-02",
    leaveType: "Earned leave",
    fromDate: "2026-07-14",
    toDate: "2026-07-18",
    days: 5,
    halfDay: false,
    reason: "Family function, native place",
    status: "Approved" as const,
    approver: "Meera Iyer",
  },
  {
    id: "LR-0921",
    appliedOn: "2026-06-05",
    leaveType: "Casual leave",
    fromDate: "2026-06-06",
    toDate: "2026-06-06",
    days: 0.5,
    halfDay: true,
    reason: "Bank work",
    status: "Rejected" as const,
    approver: "Meera Iyer",
  },
];

export const reminders = [
  {
    id: 1,
    icon: "file-text" as const,
    text: "Your resume is due for its monthly update by 25 Sep.",
    tone: "warning" as const,
  },
  {
    id: 2,
    icon: "calendar-clock" as const,
    text: "Your leave request for 8 Sep is awaiting manager approval.",
    tone: "info" as const,
  },
  {
    id: 3,
    icon: "check-circle" as const,
    text: "Your August payslip is ready to download.",
    tone: "success" as const,
  },
];

export const announcements = [
  {
    id: 1,
    title: "Diwali holiday calendar published",
    date: "28 Aug 2026",
  },
  {
    id: 2,
    title: "Q2 appraisal cycle opens next week",
    date: "25 Aug 2026",
  },
];

// -------------------- Leave module --------------------

export interface LeaveTypeInfo {
  code: string;
  name: string;
  isPaid: boolean;
  annualQuota: number;
  accrualMode: "Monthly" | "None";
  allowHalfDay: boolean;
  minNoticeDays: number;
  maxConsecutiveDays: number | null;
  attachmentRequiredAfterDays: number | null;
  carryForwardAllowed: boolean;
  maxCarryForwardDays: number | null;
}

export const leaveTypes: LeaveTypeInfo[] = [
  {
    code: "CL",
    name: "Casual leave",
    isPaid: true,
    annualQuota: 12,
    accrualMode: "Monthly",
    allowHalfDay: true,
    minNoticeDays: 1,
    maxConsecutiveDays: 3,
    attachmentRequiredAfterDays: null,
    carryForwardAllowed: false,
    maxCarryForwardDays: null,
  },
  {
    code: "SL",
    name: "Sick leave",
    isPaid: true,
    annualQuota: 12,
    accrualMode: "Monthly",
    allowHalfDay: true,
    minNoticeDays: 0,
    maxConsecutiveDays: null,
    attachmentRequiredAfterDays: 2,
    carryForwardAllowed: false,
    maxCarryForwardDays: null,
  },
  {
    code: "EL",
    name: "Earned leave",
    isPaid: true,
    annualQuota: 15,
    accrualMode: "Monthly",
    allowHalfDay: true,
    minNoticeDays: 7,
    maxConsecutiveDays: 15,
    attachmentRequiredAfterDays: null,
    carryForwardAllowed: true,
    maxCarryForwardDays: 30,
  },
  {
    code: "LOP",
    name: "Loss of pay",
    isPaid: false,
    annualQuota: 0,
    accrualMode: "None",
    allowHalfDay: true,
    minNoticeDays: 1,
    maxConsecutiveDays: null,
    attachmentRequiredAfterDays: null,
    carryForwardAllowed: false,
    maxCarryForwardDays: null,
  },
  {
    code: "COMP",
    name: "Compensatory off",
    isPaid: true,
    annualQuota: 0,
    accrualMode: "None",
    allowHalfDay: true,
    minNoticeDays: 1,
    maxConsecutiveDays: null,
    attachmentRequiredAfterDays: null,
    carryForwardAllowed: false,
    maxCarryForwardDays: null,
  },
];

export interface LeaveBalanceRow {
  code: string;
  name: string;
  annualQuota: number;
  accrued: number;
  used: number;
  balance: number;
  carryForward: number;
}

export const leaveBalanceDetailed: LeaveBalanceRow[] = [
  { code: "CL", name: "Casual leave", annualQuota: 12, accrued: 8, used: 4, balance: 4, carryForward: 0 },
  { code: "SL", name: "Sick leave", annualQuota: 12, accrued: 8, used: 6, balance: 2, carryForward: 0 },
  { code: "EL", name: "Earned leave", annualQuota: 15, accrued: 10, used: 1.5, balance: 8.5, carryForward: 3 },
  { code: "COMP", name: "Compensatory off", annualQuota: 0, accrued: 1, used: 0, balance: 1, carryForward: 0 },
];

export const holidayCalendarNote = "Next holiday: Gandhi Jayanti, 2 Oct 2026 (Fri)";

// -------------------- Profile module --------------------

export const employeeProfile = {
  fullName: "Naga Yashas",
  employeeCode: "IVB036",
  designation: "Senior Software Engineer",
  department: "Web & Application Development",
  gradeLevel: "SSE, Grade 3",
  manager: { name: "RamaKrishna Gangula", code: "IVI-0011" },
  dateOfJoining: "2022-06-13",
  employmentStatus: "Active",
  email: "naga.yashas@implevistait.com",
  contactNumber: "+91 98XXXXXX47",
  address: "Flat 4B, Silver Oak Residency, HSR Layout, Bengaluru, Karnataka 560102",
  pan: "AXXXXX234Z",
  dateOfBirth: "1996-04-18",
  bloodGroup: "O+",
};

export interface EmployeeDocument {
  id: string;
  name: string;
  category: "Identity" | "Education" | "Other";
  fileName: string;
  uploadedOn: string;
  status: "Verified" | "Pending review";
}

export const employeeDocuments: EmployeeDocument[] = [
  {
    id: "DOC-01",
    name: "Aadhaar card",
    category: "Identity",
    fileName: "aadhaar_naga_yashas.pdf",
    uploadedOn: "2022-06-15",
    status: "Verified",
  },
  {
    id: "DOC-02",
    name: "PAN card",
    category: "Identity",
    fileName: "pan_naga_yashas.pdf",
    uploadedOn: "2022-06-15",
    status: "Verified",
  },
  {
    id: "DOC-03",
    name: "10th marks card",
    category: "Education",
    fileName: "ssc_marks_card.pdf",
    uploadedOn: "2022-06-16",
    status: "Verified",
  },
  {
    id: "DOC-04",
    name: "12th marks card",
    category: "Education",
    fileName: "puc_marks_card.pdf",
    uploadedOn: "2022-06-16",
    status: "Verified",
  },
  {
    id: "DOC-05",
    name: "Degree certificate",
    category: "Education",
    fileName: "btech_degree_certificate.pdf",
    uploadedOn: "2022-06-16",
    status: "Pending review",
  },
];
