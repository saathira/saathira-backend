import { useState, useEffect } from 'react';
import { Sidebar, AdminTab } from './components/Sidebar';
import { Header } from './components/Header';
import { DashboardPage } from './pages/DashboardPage';
import { VerificationsPage } from './pages/VerificationsPage';
import { UsersPage } from './pages/UsersPage';
import { BookingsPage } from './pages/BookingsPage';
import { PaymentsPage } from './pages/PaymentsPage';
import { SafetyPage } from './pages/SafetyPage';
import { AuditLogsPage } from './pages/AuditLogsPage';
import { LoginPage } from './pages/LoginPage';
import { adminApi } from './api/client';

export function App() {
  const [token, setToken] = useState<string | null>(
    localStorage.getItem('saathira_admin_token')
  );
  const [tab, setTab] = useState<AdminTab>('dashboard');
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const fetchStats = async () => {
    if (!token) return;
    setLoading(true);
    try {
      const data = await adminApi.getStats();
      setStats(data);
    } catch (err) {
      console.error('Failed to load stats', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (token) {
      fetchStats();
    }
  }, [token]);

  const handleLogout = () => {
    localStorage.removeItem('saathira_admin_token');
    setToken(null);
  };

  if (!token) {
    return <LoginPage onLoginSuccess={(t) => setToken(t)} />;
  }

  const getTabTitle = () => {
    switch (tab) {
      case 'dashboard':
        return { title: 'Executive Overview', subtitle: 'Real-time marketplace activity & health' };
      case 'verifications':
        return { title: 'Companion ID Verification Queue', subtitle: 'Review government identification documents' };
      case 'users':
        return { title: 'User & Companion Directory', subtitle: 'Manage active customer and companion accounts' };
      case 'bookings':
        return { title: 'Marketplace Bookings Feed', subtitle: 'Track meeting states, schedules, and locations' };
      case 'payments':
        return { title: 'Financials & Escrow Ledger', subtitle: 'Razorpay transactions and companion UPI payouts' };
      case 'safety':
        return { title: 'Trust, Safety & Incident Mediation', subtitle: 'Investigate reports and resolve booking disputes' };
      case 'audit':
        return { title: 'System & Admin Audit Logs', subtitle: 'Chronological record of administrative operations' };
    }
  };

  const headerMeta = getTabTitle();

  return (
    <div className="flex min-h-screen bg-brand-dark">
      <Sidebar
        currentTab={tab}
        onSelectTab={(t) => setTab(t)}
        pendingVerifications={stats?.users?.pendingVerifications ?? 0}
        openReports={(stats?.trustAndSafety?.openReports ?? 0) + (stats?.trustAndSafety?.openDisputes ?? 0)}
        onLogout={handleLogout}
      />

      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title={headerMeta.title}
          subtitle={headerMeta.subtitle}
          onRefresh={fetchStats}
          loading={loading}
        />

        <main className="flex-1 pb-16">
          {tab === 'dashboard' && (
            <DashboardPage stats={stats} onNavigateTab={(t) => setTab(t)} />
          )}
          {tab === 'verifications' && <VerificationsPage />}
          {tab === 'users' && <UsersPage />}
          {tab === 'bookings' && <BookingsPage />}
          {tab === 'payments' && <PaymentsPage />}
          {tab === 'safety' && <SafetyPage />}
          {tab === 'audit' && <AuditLogsPage />}
        </main>
      </div>
    </div>
  );
}
export default App;
