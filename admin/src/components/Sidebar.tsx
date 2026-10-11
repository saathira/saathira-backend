import React from 'react';
import {
  LayoutDashboard,
  ShieldCheck,
  Users,
  Calendar,
  CreditCard,
  AlertTriangle,
  FileText,
  LogOut,
  Sparkles,
} from 'lucide-react';

export type AdminTab =
  | 'dashboard'
  | 'verifications'
  | 'users'
  | 'bookings'
  | 'payments'
  | 'safety'
  | 'audit';

interface SidebarProps {
  currentTab: AdminTab;
  onSelectTab: (tab: AdminTab) => void;
  pendingVerifications?: number;
  openReports?: number;
  onLogout: () => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  currentTab,
  onSelectTab,
  pendingVerifications = 0,
  openReports = 0,
  onLogout,
}) => {
  const navItems = [
    { id: 'dashboard' as AdminTab, label: 'Dashboard', icon: LayoutDashboard },
    {
      id: 'verifications' as AdminTab,
      label: 'ID Verifications',
      icon: ShieldCheck,
      badge: pendingVerifications,
      badgeColor: 'bg-amber-500/20 text-amber-300 border border-amber-500/30',
    },
    { id: 'users' as AdminTab, label: 'Users & Companions', icon: Users },
    { id: 'bookings' as AdminTab, label: 'Bookings Stream', icon: Calendar },
    { id: 'payments' as AdminTab, label: 'Payments & Payouts', icon: CreditCard },
    {
      id: 'safety' as AdminTab,
      label: 'Safety & Disputes',
      icon: AlertTriangle,
      badge: openReports,
      badgeColor: 'bg-rose-500/20 text-rose-300 border border-rose-500/30',
    },
    { id: 'audit' as AdminTab, label: 'Audit Logs', icon: FileText },
  ];

  return (
    <aside className="w-64 bg-brand-card border-r border-brand-border flex flex-col justify-between h-screen sticky top-0">
      <div>
        {/* Brand Header */}
        <div className="p-6 border-b border-brand-border flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-brand-primary to-brand-accent flex items-center justify-center shadow-lg shadow-purple-500/20">
              <Sparkles className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-lg text-white leading-tight">Saathira</h1>
              <span className="text-[11px] font-semibold text-brand-primary tracking-wider uppercase">
                Admin Console
              </span>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="p-4 space-y-1.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentTab === item.id;

            return (
              <button
                key={item.id}
                onClick={() => onSelectTab(item.id)}
                className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl font-medium text-sm transition-all duration-150 ${
                  isActive
                    ? 'bg-brand-primary text-white shadow-md shadow-purple-600/30'
                    : 'text-slate-400 hover:text-white hover:bg-white/[0.04]'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4.5 h-4.5 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                  <span>{item.label}</span>
                </div>
                {item.badge != null && item.badge > 0 && (
                  <span
                    className={`text-xs px-2 py-0.5 rounded-full font-bold ${
                      isActive ? 'bg-white text-brand-primary' : item.badgeColor
                    }`}
                  >
                    {item.badge}
                  </span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Footer Profile & Logout */}
      <div className="p-4 border-t border-brand-border">
        <button
          onClick={onLogout}
          className="w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium text-slate-400 hover:text-rose-300 hover:bg-rose-500/10 transition-colors"
        >
          <LogOut className="w-4.5 h-4.5 text-rose-400" />
          <span>Sign Out</span>
        </button>
      </div>
    </aside>
  );
};
