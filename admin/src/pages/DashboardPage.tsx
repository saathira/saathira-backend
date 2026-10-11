import React from 'react';
import {
  Users,
  ShieldAlert,
  CalendarCheck,
  TrendingUp,
  DollarSign,
  AlertCircle,
  Activity as ActivityIcon,
} from 'lucide-react';
import { MetricCard } from '../components/MetricCard';

interface DashboardPageProps {
  stats: any;
  onNavigateTab: (tab: any) => void;
}

export const DashboardPage: React.FC<DashboardPageProps> = ({ stats, onNavigateTab }) => {
  const users = stats?.users || {};
  const bookings = stats?.bookings || {};
  const safety = stats?.trustAndSafety || {};
  const recent = stats?.recentBookings || [];

  return (
    <div className="p-8 space-y-8">
      {/* Top Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        <MetricCard
          label="Total Users"
          value={users.total ?? 0}
          subtext={`${users.companions ?? 0} Companions (${users.activeCompanions ?? 0} Active)`}
          icon={Users}
          iconColor="text-purple-400"
        />
        <MetricCard
          label="Pending Verifications"
          value={users.pendingVerifications ?? 0}
          subtext="ID & Selfie review required"
          icon={ShieldAlert}
          iconColor="text-amber-400"
        />
        <MetricCard
          label="Total Bookings"
          value={bookings.total ?? 0}
          subtext={`${bookings.completed ?? 0} Completed • ${bookings.confirmed ?? 0} Active`}
          icon={CalendarCheck}
          iconColor="text-cyan-400"
        />
        <MetricCard
          label="Platform Revenue"
          value={`₹${(bookings.commissionRupees ?? 0).toLocaleString()}`}
          subtext={`GMV: ₹${(bookings.gmvRupees ?? 0).toLocaleString()}`}
          icon={DollarSign}
          iconColor="text-emerald-400"
          trend="+20% fee"
        />
      </div>

      {/* Safety & Action Alert Banners */}
      {(users.pendingVerifications > 0 || safety.openReports > 0 || safety.openDisputes > 0) && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {users.pendingVerifications > 0 && (
            <div
              onClick={() => onNavigateTab('verifications')}
              className="p-4 rounded-xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-between cursor-pointer hover:bg-amber-500/15 transition-colors"
            >
              <div className="flex items-center gap-3">
                <ShieldAlert className="w-5 h-5 text-amber-400" />
                <div>
                  <h4 className="text-sm font-bold text-amber-200">
                    {users.pendingVerifications} Verification(s) Pending
                  </h4>
                  <p className="text-xs text-amber-300/70">Review Government IDs</p>
                </div>
              </div>
              <span className="text-xs font-semibold text-amber-400">Review →</span>
            </div>
          )}

          {safety.openReports > 0 && (
            <div
              onClick={() => onNavigateTab('safety')}
              className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 flex items-center justify-between cursor-pointer hover:bg-rose-500/15 transition-colors"
            >
              <div className="flex items-center gap-3">
                <AlertCircle className="w-5 h-5 text-rose-400" />
                <div>
                  <h4 className="text-sm font-bold text-rose-200">
                    {safety.openReports} Safety Report(s)
                  </h4>
                  <p className="text-xs text-rose-300/70">Requires urgent investigation</p>
                </div>
              </div>
              <span className="text-xs font-semibold text-rose-400">Investigate →</span>
            </div>
          )}

          {safety.openDisputes > 0 && (
            <div
              onClick={() => onNavigateTab('safety')}
              className="p-4 rounded-xl bg-purple-500/10 border border-purple-500/30 flex items-center justify-between cursor-pointer hover:bg-purple-500/15 transition-colors"
            >
              <div className="flex items-center gap-3">
                <ActivityIcon className="w-5 h-5 text-purple-400" />
                <div>
                  <h4 className="text-sm font-bold text-purple-200">
                    {safety.openDisputes} Open Booking Dispute(s)
                  </h4>
                  <p className="text-xs text-purple-300/70">Mediation & Refund queue</p>
                </div>
              </div>
              <span className="text-xs font-semibold text-purple-400">Resolve →</span>
            </div>
          )}
        </div>
      )}

      {/* Recent Bookings Stream Table */}
      <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
        <div className="p-5 border-b border-brand-border flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <TrendingUp className="w-5 h-5 text-brand-primary" />
            <h3 className="font-bold text-white text-base">Live Bookings Feed</h3>
          </div>
          <button
            onClick={() => onNavigateTab('bookings')}
            className="text-xs font-semibold text-brand-primary hover:underline"
          >
            View all bookings →
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
              <tr>
                <th className="py-3 px-5">Customer</th>
                <th className="py-3 px-5">Companion</th>
                <th className="py-3 px-5">Activity</th>
                <th className="py-3 px-5">Date & Time</th>
                <th className="py-3 px-5">Amount</th>
                <th className="py-3 px-5">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/[0.04]">
              {recent.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    No recent booking activity
                  </td>
                </tr>
              ) : (
                recent.map((b: any) => (
                  <tr key={b.id} className="hover:bg-white/[0.02] transition-colors">
                    <td className="py-3.5 px-5 font-semibold text-white">
                      {b.customer?.fullName ?? 'Customer'}
                    </td>
                    <td className="py-3.5 px-5 font-medium text-slate-300">
                      {b.companion?.user?.fullName ?? 'Companion'}
                    </td>
                    <td className="py-3.5 px-5 text-slate-400">{b.activity?.name ?? 'Meeting'}</td>
                    <td className="py-3.5 px-5 text-slate-400">
                      {new Date(b.startAt).toLocaleDateString('en-IN', {
                        day: 'numeric',
                        month: 'short',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </td>
                    <td className="py-3.5 px-5 font-bold text-white">₹{b.amount / 100}</td>
                    <td className="py-3.5 px-5">
                      <span
                        className={`px-2.5 py-1 rounded-full text-[11px] font-bold ${
                          b.status === 'CONFIRMED'
                            ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                            : b.status === 'COMPLETED'
                            ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/30'
                            : b.status === 'PENDING'
                            ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                            : 'bg-slate-500/20 text-slate-300'
                        }`}
                      >
                        {b.status}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
