import { type LucideIcon } from "lucide-react";
import "./PlaceholderPage.css";

interface PlaceholderPageProps {
  icon: LucideIcon;
  title: string;
  description: string;
}

export default function PlaceholderPage({ icon: Icon, title, description }: PlaceholderPageProps) {
  return (
    <main className="placeholder-page">
      <div className="placeholder-page__icon">
        <Icon size={22} strokeWidth={1.6} aria-hidden="true" />
      </div>
      <h1 className="placeholder-page__title">{title}</h1>
      <p className="placeholder-page__description">{description}</p>
    </main>
  );
}
