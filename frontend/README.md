# IVConnect — Employee portal

A reference UI for the IVConnect Employee & Business Portal's employee-role
screens: Dashboard, Leave (apply / requests / balance), and My profile
(details / documents).

Built with React 18 + TypeScript + Vite, React Router for navigation, plain
CSS (no framework), teal-led design tokens, and
[lucide-react](https://lucide.dev) icons. Data in `src/data/mockData.ts` is
placeholder — shaped the way the real `/api/v1/me/*` endpoints would return
it, so it's a straightforward swap once the backend exists.

## Run it locally

Requires Node.js 18+.

```bash
npm install
npm run dev
```

Then open the URL Vite prints (usually `http://localhost:5173`).

## Build for production

```bash
npm run build
npm run preview
```

## Screens

- **Dashboard** (`/`) — greeting, KPI summary (leave balance, latest
  payslip, resume compliance, pending requests), recent payslips, resume
  status, leave balance breakdown, reminders, announcements.
- **Leave** (`/leave`) — three tabs:
  - *Apply for leave* — form with leave-type rules applied dynamically
    (half-day eligibility, minimum notice, max consecutive days, and a
    conditional attachment requirement e.g. Sick Leave beyond 2 days).
  - *My requests* — request history with status badges and cancel action
    on pending requests.
  - *My balance* — per-type balance cards plus a full ledger-style detail
    table (quota, accrued, used, carry-forward, balance).
- **My profile** (`/profile`) — two tabs:
  - *Profile details* — employment, contact and personal info, including
    a masked PAN with a reveal/hide toggle and an audit-log note.
  - *Documents* — uploaded documents grouped by category (Identity:
    Aadhaar, PAN card; Education: marks cards, degree certificate), each
    with a verification status and view/download actions.
- **Payslips** / **Resume** (`/payslips`, `/resume`) — placeholder pages;
  not yet built out beyond what the Dashboard already shows.

## Project structure

```
src/
  index.css                design tokens (colors, type, spacing) + base styles
  App.tsx                  routes + app shell (sidebar + topbar)
  data/mockData.ts         placeholder data, shaped like future API responses
  utils/
    resumeCompliance.ts    tri-state resume compliance logic (30/45 day rules)
  pages/
    DashboardPage.tsx
    LeavePage.tsx           tab container for the three leave tabs
    ProfilePage.tsx         tab container for the two profile tabs
    PlaceholderPage.tsx     generic "not built yet" screen
  components/
    Sidebar.tsx             left navigation (React Router NavLink)
    Topbar.tsx              search, notifications, profile
    KpiCard.tsx              summary metric card
    StatusBadge.tsx          shared status pill (success/warning/danger/neutral)
    PillTabs.tsx             shared sub-navigation tabs
    LeaveBalanceCard.tsx     dashboard leave balance + stacked breakdown bar
    PayslipTable.tsx         dashboard recent payslips list
    ResumeStatusCard.tsx     dashboard resume compliance status
    RemindersCard.tsx        dashboard action reminders
    AnnouncementsCard.tsx    dashboard company announcements
    leave/
      ApplyLeaveTab.tsx      leave application form
      MyRequestsTab.tsx      leave request history table
      MyBalanceTab.tsx       leave balance detail
    profile/
      ProfileDetailsTab.tsx  employee master fields
      DocumentsTab.tsx       uploaded document list by category
```

## Notes for the real build

- This mockup shows the **Employee**-role view only. Other roles (Manager,
  HR Admin, Payroll Admin, Sales) get a different sidebar and different
  landing metrics — build each as its own route guarded by role, not as
  conditionally-hidden items in one shared component. In particular, the
  Sales CRM module should not appear anywhere in a non-Sales/Admin user's
  bundle or DOM — the API returns 404 (not 403) for those roles so the
  module's existence isn't disclosed, and the frontend should mirror that
  by simply not shipping the nav entry or route for them.
- Replace `mockData.ts` with real API calls once the backend is live; the
  shapes are intentionally close to what the endpoint catalogue in the
  technical design doc returns.
- Resume compliance state (`utils/resumeCompliance.ts`) is calculated
  client-side here for display purposes; the real system of record is the
  monthly Hangfire background job that recalculates it server-side and
  drives the reminder notifications.
- Payslip downloads and document view/download actions should call an
  authorised streaming endpoint with a short-lived signed URL — never a
  direct file link.
- The "Apply for leave" form validates client-side only; the server must
  re-validate every rule (notice period, max consecutive days, attachment
  requirement, balance sufficiency) since client-side checks are
  trivially bypassable.

