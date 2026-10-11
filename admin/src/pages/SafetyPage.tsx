import React, { useState, useEffect } from 'react';
import { adminApi } from '../api/client';

export const SafetyPage: React.FC = () => {
  const [tab, setTab] = useState<'reports' | 'disputes'>('reports');
  const [reports, setReports] = useState<any[]>([]);
  const [disputes, setDisputes] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const [selectedItem, setSelectedItem] = useState<any | null>(null);
  const [resolveNote, setResolveNote] = useState('');
  const [suspendUser, setSuspendUser] = useState(false);
  const [refundCustomer, setRefundCustomer] = useState(false);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (tab === 'reports') {
        const res = await adminApi.getReports();
        setReports(res.items || []);
      } else {
        const res = await adminApi.getDisputes();
        setDisputes(res.items || []);
      }
    } catch (err) {
      console.error('Failed to load safety data', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [tab]);

  const handleResolveReport = async (id: string) => {
    if (!resolveNote.trim()) {
      alert('Please provide a resolution note');
      return;
    }
    try {
      await adminApi.resolveReport(id, resolveNote, suspendUser);
      setSelectedItem(null);
      setResolveNote('');
      fetchData();
    } catch (err: any) {
      alert(`Resolution failed: ${err.message}`);
    }
  };

  const handleResolveDispute = async (id: string) => {
    if (!resolveNote.trim()) {
      alert('Please provide a dispute resolution outcome');
      return;
    }
    try {
      await adminApi.resolveDispute(id, resolveNote, refundCustomer);
      setSelectedItem(null);
      setResolveNote('');
      fetchData();
    } catch (err: any) {
      alert(`Resolution failed: ${err.message}`);
    }
  };

  return (
    <div className="p-8 space-y-6">
      {/* Sub tabs */}
      <div className="flex items-center gap-3">
        <button
          onClick={() => setTab('reports')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors ${
            tab === 'reports'
              ? 'bg-brand-primary text-white shadow-md'
              : 'bg-brand-card text-slate-400 border border-brand-border hover:text-white'
          }`}
        >
          Incident Reports & Safety Violations
        </button>
        <button
          onClick={() => setTab('disputes')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors ${
            tab === 'disputes'
              ? 'bg-brand-primary text-white shadow-md'
              : 'bg-brand-card text-slate-400 border border-brand-border hover:text-white'
          }`}
        >
          Booking Mediation & Disputes
        </button>
      </div>

      {tab === 'reports' ? (
        /* Reports Table */
        <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
                <tr>
                  <th className="py-3.5 px-5">Reporter</th>
                  <th className="py-3.5 px-5">Reported User</th>
                  <th className="py-3.5 px-5">Reason</th>
                  <th className="py-3.5 px-5">Details</th>
                  <th className="py-3.5 px-5">Status</th>
                  <th className="py-3.5 px-5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/[0.04]">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">
                      Loading reports...
                    </td>
                  </tr>
                ) : reports.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">
                      No reports recorded
                    </td>
                  </tr>
                ) : (
                  reports.map((r) => (
                    <tr key={r.id} className="hover:bg-white/[0.02] transition-colors">
                      <td className="py-3.5 px-5 font-semibold text-white">
                        {r.reporter?.fullName ?? 'User'}
                      </td>
                      <td className="py-3.5 px-5">
                        <div className="font-semibold text-rose-300">
                          {r.reportedUser?.fullName ?? 'Reported User'}
                        </div>
                        <div className="text-[10px] text-slate-400">
                          Status: {r.reportedUser?.status}
                        </div>
                      </td>
                      <td className="py-3.5 px-5 font-medium text-amber-300">{r.reason}</td>
                      <td className="py-3.5 px-5 text-slate-300 max-w-[240px] truncate">
                        {r.details ?? 'No additional details provided'}
                      </td>
                      <td className="py-3.5 px-5">
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            r.status === 'RESOLVED'
                              ? 'bg-emerald-500/20 text-emerald-300'
                              : 'bg-rose-500/20 text-rose-300'
                          }`}
                        >
                          {r.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-5 text-right">
                        {r.status !== 'RESOLVED' && (
                          <button
                            onClick={() => setSelectedItem(r)}
                            className="px-3 py-1 rounded-lg bg-rose-500/20 text-rose-300 hover:bg-rose-500 hover:text-white font-semibold transition-colors"
                          >
                            Investigate
                          </button>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        /* Disputes Table */
        <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
                <tr>
                  <th className="py-3.5 px-5">Booking ID</th>
                  <th className="py-3.5 px-5">Parties</th>
                  <th className="py-3.5 px-5">Dispute Reason</th>
                  <th className="py-3.5 px-5">Resolution Outcome</th>
                  <th className="py-3.5 px-5">Status</th>
                  <th className="py-3.5 px-5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/[0.04]">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">
                      Loading disputes...
                    </td>
                  </tr>
                ) : disputes.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">
                      No disputes active
                    </td>
                  </tr>
                ) : (
                  disputes.map((d) => (
                    <tr key={d.id} className="hover:bg-white/[0.02] transition-colors">
                      <td className="py-3.5 px-5 font-mono text-purple-300">
                        #{d.bookingId.slice(0, 8)}
                      </td>
                      <td className="py-3.5 px-5 text-slate-300">
                        <div>Client: {d.booking?.customer?.fullName}</div>
                        <div>Companion: {d.booking?.companion?.user?.fullName}</div>
                      </td>
                      <td className="py-3.5 px-5 text-amber-300 font-medium">{d.reason}</td>
                      <td className="py-3.5 px-5 text-slate-300">
                        {d.resolution ?? 'Pending mediation'}
                      </td>
                      <td className="py-3.5 px-5">
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            d.status === 'RESOLVED'
                              ? 'bg-emerald-500/20 text-emerald-300'
                              : 'bg-amber-500/20 text-amber-300'
                          }`}
                        >
                          {d.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-5 text-right">
                        {d.status !== 'RESOLVED' && (
                          <button
                            onClick={() => setSelectedItem(d)}
                            className="px-3 py-1 rounded-lg bg-purple-500/20 text-purple-300 hover:bg-purple-500 hover:text-white font-semibold transition-colors"
                          >
                            Mediate
                          </button>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Resolution Modal */}
      {selectedItem && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-brand-card w-full max-w-lg rounded-2xl border border-brand-border p-6 space-y-4 shadow-2xl">
            <h3 className="font-bold text-white text-base">
              {tab === 'reports' ? 'Resolve Safety Report' : 'Resolve Booking Dispute'}
            </h3>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-300">Resolution Decision & Notes</label>
              <textarea
                value={resolveNote}
                onChange={(e) => setResolveNote(e.target.value)}
                placeholder="Explain the admin verdict and action taken..."
                rows={3}
                className="w-full bg-brand-dark rounded-xl border border-brand-border p-3 text-xs text-slate-200 placeholder:text-slate-500 focus:outline-none focus:border-brand-primary"
              />
            </div>

            {tab === 'reports' ? (
              <label className="flex items-center gap-2 text-xs text-rose-300 cursor-pointer">
                <input
                  type="checkbox"
                  checked={suspendUser}
                  onChange={(e) => setSuspendUser(e.target.checked)}
                  className="rounded bg-brand-dark border-brand-border text-rose-500"
                />
                <span>Also suspend reported user account for policy violation</span>
              </label>
            ) : (
              <label className="flex items-center gap-2 text-xs text-purple-300 cursor-pointer">
                <input
                  type="checkbox"
                  checked={refundCustomer}
                  onChange={(e) => setRefundCustomer(e.target.checked)}
                  className="rounded bg-brand-dark border-brand-border text-purple-500"
                />
                <span>Issue full refund to customer via Escrow</span>
              </label>
            )}

            <div className="flex items-center justify-end gap-3 pt-3">
              <button
                onClick={() => setSelectedItem(null)}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-400 hover:text-white"
              >
                Cancel
              </button>
              <button
                onClick={() =>
                  tab === 'reports'
                    ? handleResolveReport(selectedItem.id)
                    : handleResolveDispute(selectedItem.id)
                }
                className="px-5 py-2 rounded-xl bg-brand-primary text-white text-xs font-bold hover:bg-brand-primaryHover transition-colors"
              >
                Submit Resolution
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
