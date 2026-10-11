import React, { useState, useEffect } from 'react';
import { adminApi } from '../api/client';

export const PaymentsPage: React.FC = () => {
  const [tab, setTab] = useState<'payments' | 'payouts'>('payments');
  const [payments, setPayments] = useState<any[]>([]);
  const [payouts, setPayouts] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchData = async () => {
    setLoading(true);
    try {
      if (tab === 'payments') {
        const res = await adminApi.getPayments();
        setPayments(res.items || []);
      } else {
        const res = await adminApi.getPayouts();
        setPayouts(res.items || []);
      }
    } catch (err) {
      console.error('Failed to load financial records', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [tab]);

  const handleApprovePayout = async (id: string) => {
    try {
      await adminApi.approvePayout(id);
      alert('Payout approved and marked paid.');
      fetchData();
    } catch (err: any) {
      alert(`Approval failed: ${err.message}`);
    }
  };

  return (
    <div className="p-8 space-y-6">
      {/* Sub tabs */}
      <div className="flex items-center gap-3">
        <button
          onClick={() => setTab('payments')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors ${
            tab === 'payments'
              ? 'bg-brand-primary text-white shadow-md'
              : 'bg-brand-card text-slate-400 border border-brand-border hover:text-white'
          }`}
        >
          Customer Payments (Razorpay Escrow)
        </button>
        <button
          onClick={() => setTab('payouts')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors ${
            tab === 'payouts'
              ? 'bg-brand-primary text-white shadow-md'
              : 'bg-brand-card text-slate-400 border border-brand-border hover:text-white'
          }`}
        >
          Companion Payouts & UPI Transfers
        </button>
      </div>

      {tab === 'payments' ? (
        /* Payments Table */
        <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
                <tr>
                  <th className="py-3.5 px-5">Razorpay Order ID</th>
                  <th className="py-3.5 px-5">Payment ID</th>
                  <th className="py-3.5 px-5">Customer</th>
                  <th className="py-3.5 px-5">Companion</th>
                  <th className="py-3.5 px-5">Amount</th>
                  <th className="py-3.5 px-5">Date</th>
                  <th className="py-3.5 px-5 text-right">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/[0.04]">
                {loading ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-slate-400">
                      Loading payment transactions...
                    </td>
                  </tr>
                ) : payments.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="py-8 text-center text-slate-400">
                      No payment records found
                    </td>
                  </tr>
                ) : (
                  payments.map((p) => (
                    <tr key={p.id} className="hover:bg-white/[0.02] transition-colors">
                      <td className="py-3.5 px-5 font-mono text-purple-300">{p.razorpayOrderId}</td>
                      <td className="py-3.5 px-5 font-mono text-slate-300">
                        {p.razorpayPaymentId ?? 'Pending capture'}
                      </td>
                      <td className="py-3.5 px-5 font-medium text-white">
                        {p.booking?.customer?.fullName ?? 'Customer'}
                      </td>
                      <td className="py-3.5 px-5 text-slate-300">
                        {p.booking?.companion?.user?.fullName ?? 'Companion'}
                      </td>
                      <td className="py-3.5 px-5 font-bold text-white">₹{p.amount / 100}</td>
                      <td className="py-3.5 px-5 text-slate-400">
                        {new Date(p.createdAt).toLocaleDateString('en-IN', {
                          day: 'numeric',
                          month: 'short',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </td>
                      <td className="py-3.5 px-5 text-right">
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            p.status === 'CAPTURED'
                              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                              : 'bg-amber-500/20 text-amber-300'
                          }`}
                        >
                          {p.status}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        /* Payouts Table */
        <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
                <tr>
                  <th className="py-3.5 px-5">Companion</th>
                  <th className="py-3.5 px-5">UPI VPA Address</th>
                  <th className="py-3.5 px-5">Payout Amount</th>
                  <th className="py-3.5 px-5">Requested At</th>
                  <th className="py-3.5 px-5">Status</th>
                  <th className="py-3.5 px-5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/[0.04]">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">
                      Loading companion payouts...
                    </td>
                  </tr>
                ) : payouts.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-400">
                      No pending payouts
                    </td>
                  </tr>
                ) : (
                  payouts.map((py) => (
                    <tr key={py.id} className="hover:bg-white/[0.02] transition-colors">
                      <td className="py-3.5 px-5 font-semibold text-white">
                        {py.companion?.user?.fullName ?? 'Companion'}
                      </td>
                      <td className="py-3.5 px-5 font-mono text-cyan-300">
                        {py.companion?.payoutUpi ?? 'Not configured'}
                      </td>
                      <td className="py-3.5 px-5 font-bold text-emerald-400">₹{py.amount / 100}</td>
                      <td className="py-3.5 px-5 text-slate-400">
                        {new Date(py.createdAt).toLocaleDateString('en-IN')}
                      </td>
                      <td className="py-3.5 px-5">
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            py.status === 'PAID'
                              ? 'bg-emerald-500/20 text-emerald-300'
                              : 'bg-amber-500/20 text-amber-300'
                          }`}
                        >
                          {py.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-5 text-right">
                        {py.status !== 'PAID' && (
                          <button
                            onClick={() => handleApprovePayout(py.id)}
                            className="px-3 py-1 rounded-lg bg-emerald-600 text-white font-semibold hover:bg-emerald-500 transition-colors"
                          >
                            Mark Paid
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
    </div>
  );
};
