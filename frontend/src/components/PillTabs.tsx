import "./PillTabs.css";

interface PillTabsProps {
  tabs: string[];
  active: string;
  onChange: (tab: string) => void;
}

export default function PillTabs({ tabs, active, onChange }: PillTabsProps) {
  return (
    <div className="pill-tabs" role="tablist">
      {tabs.map((tab) => (
        <button
          key={tab}
          role="tab"
          aria-selected={tab === active}
          className={tab === active ? "pill-tabs__tab pill-tabs__tab--active" : "pill-tabs__tab"}
          onClick={() => onChange(tab)}
        >
          {tab}
        </button>
      ))}
    </div>
  );
}
