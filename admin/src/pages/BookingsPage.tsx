import React, { useState, useEffect } from 'react';
import { MapPin } from 'lucide-react';
import { adminApi } from '../api/client';

export const BookingsPage: React.FC = () => {
  const [bookings, setBookings] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState('');

  const fetchBookings = async () => {
    setLoading(true);
    try {
      const res = await adminApi.getBookings(statusFilter);
      setBookings(res.items || []);
    } catch (err) {
      console.error('Failed to load bookings', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchBookings();
  }, [statusFilter]);

  return (
    <div className="p-8 space-y-6">
      {/* Filters */}
      <div className="flex items-center justify-between">
        <div className="flex flex-wrap items-center gap-2 bg-brand-card p-1 rounded-xl border border-brand-border">
          {[
            { id: '', label: 'All' },
            { id: 'CONFIRMED', label: 'Confirmed' },
            { id: 'IN_PROGRESS', label: 'In Progress' },
            { id: 'PAYMENT_PENDING', label: 'Payment Pending' },
            { id: 'PENDING', label: 'Pending' },
            { id: 'COMPLETED', label: 'Completed' },
            { id: 'CANCELLED', label: 'Cancelled' },
            { id: 'DISPUTED', label: 'Disputed' },
          ].map((s) => (
            <button
              key={s.id}
              onClick={() => setStatusFilter(s.id)}
              className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors ${
                statusFilter === s.id
                  ? 'bg-brand-primary text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              {s.label}
            </button>
          ))}
        </div>
        <span className="text-xs text-slate-400">{bookings.length} bookings</span>
      </div>

      {/* Bookings Table */}
      <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
              <tr>
                <th className="py-3.5 px-5">Booking ID</th>
                <th className="py-3.5 px-5">Customer</th>
                <th className="py-3.5 px-5">Companion</th>
                <th className="py-3.5 px-5">Activity & Location</th>
                <th className="py-3.5 px-5">Schedule</th>
                <th className="py-3.5 px-5">Amount</th>
                <th className="py-3.5 px-5 text-right">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/[0.04]">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400">
                    Loading bookings...
                  </td>
                </tr>
              ) : bookings.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400">
                    No bookings found
                  </td>
                </tr>
              ) : (
                bookings.map((b) => (
                  <tr key={b.id} className="hover:bg-white/[0.02] transition-colors">
                    <td className="py-3.5 px-5 font-mono text-[11px] text-purple-300">
                      #{b.id.slice(0, 8)}
                    </td>
                    <td className="py-3.5 px-5">
                      <div className="font-semibold text-white">{b.customer?.fullName ?? 'Customer'}</div>
                      <div className="text-[11px] text-slate-400">{b.customer?.phone}</div>
                    </td>
                    <td className="py-3.5 px-5">
                      <div className="font-semibold text-white">
                        {b.companion?.user?.fullName ?? 'Companion'}
                      </div>
                      <div className="text-[11px] text-slate-400">{b.companion?.user?.phone}</div>
                    </td>
                    <td className="py-3.5 px-5">
                      <div className="font-medium text-slate-200">{b.activity?.name ?? 'Meeting'}</div>
                      <div className="text-[11px] text-slate-400 flex items-center gap-1 mt-0.5 max-w-[200px] truncate">
                        <MapPin className="w-3 h-3 text-brand-primary shrink-0" />
                        <span>{b.meetingPlace}</span>
                      </div>
                    </td>
                    <td className="py-3.5 px-5 text-slate-300">
                      {new Date(b.startAt).toLocaleDateString('en-IN', {
                        day: 'numeric',
                        month: 'short',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </td>
                    <td className="py-3.5 px-5">
                      <div className="font-bold text-white">₹{b.amount / 100}</div>
                      <div className="text-[10px] text-emerald-400">Fee: ₹{b.commission / 100}</div>
                    </td>
                    <td className="py-3.5 px-5 text-right">
                      <span
                        className={`px-2.5 py-1 rounded-full text-[11px] font-bold ${
                          b.status === 'CONFIRMED'
                            ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                            : b.status === 'COMPLETED'
                            ? 'bg-cyan-500/20 text-cyan-300 border border-cyan-500/30'
                            : b.status === 'PENDING'
                            ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                            : b.status === 'DISPUTED'
                            ? 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
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
