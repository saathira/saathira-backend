import React from 'react';
import { RefreshCw, Bell } from 'lucide-react';

interface HeaderProps {
  title: string;
  subtitle?: string;
  onRefresh?: () => void;
  loading?: boolean;
}

export const Header: React.FC<HeaderProps> = ({
  title,
  subtitle,
  onRefresh,
  loading = false,
}) => {
  return (
    <header className="px-8 py-5 border-b border-brand-border bg-brand-dark/80 backdrop-blur sticky top-0 z-10 flex items-center justify-between">
      <div>
        <h2 className="text-xl font-bold text-white">{title}</h2>
        {subtitle && <p className="text-xs text-slate-400 mt-0.5">{subtitle}</p>}
      </div>

      <div className="flex items-center gap-3">
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={loading}
            className="flex items-center gap-2 px-3 py-1.5 rounded-lg border border-brand-border bg-brand-card hover:bg-white/[0.06] text-xs font-medium text-slate-300 transition-colors disabled:opacity-50"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin text-brand-primary' : ''}`} />
            <span>Refresh</span>
          </button>
        )}
        <div className="w-8 h-8 rounded-lg bg-brand-card border border-brand-border flex items-center justify-center text-slate-400">
          <Bell className="w-4 h-4" />
        </div>
      </div>
    </header>
  );
};
