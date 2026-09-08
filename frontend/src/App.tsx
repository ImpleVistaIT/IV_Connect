import { BrowserRouter, Routes, Route } from "react-router-dom";
import { FileEdit } from "lucide-react";
import Sidebar from "./components/Sidebar";
import Topbar from "./components/Topbar";
import DashboardPage from "./pages/DashboardPage";
import LeavePage from "./pages/LeavePage";
import ProfilePage from "./pages/ProfilePage";
import PayslipsPage from "./pages/PayslipsPage";
import PlaceholderPage from "./pages/PlaceholderPage";
import "./App.css";

export default function App() {
  return (
    <BrowserRouter>
      <div className="app-shell">
        <Sidebar />
        <div className="app-shell__body">
          <Topbar />
          <Routes>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/leave" element={<LeavePage />} />
            <Route path="/payslips" element={<PayslipsPage />} />
            <Route
              path="/resume"
              element={
                <PlaceholderPage
                  icon={FileEdit}
                  title="Resume"
                  description="Maintain your structured resume sections here — the fixed format is generated from what you fill in, not an uploaded file."
                />
              }
            />
          </Routes>
        </div>
      </div>
    </BrowserRouter>
  );
}
