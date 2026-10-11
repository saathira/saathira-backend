import React, { useState, useEffect } from 'react';
import { Search, Shield, Bell, Send, X, CheckCircle2, AlertCircle, Smartphone } from 'lucide-react';
import { adminApi } from '../api/client';

export const UsersPage: React.FC = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState('');

  // Notification Test Modal State
  const [modalOpen, setModalOpen] = useState(false);
  const [selectedUser, setSelectedUser] = useState<any | null>(null);
  const [targetMode, setTargetMode] = useState<'USER' | 'ALL'>('USER');
  const [notifTitle, setNotifTitle] = useState('Saathira Platform Alert');
  const [notifBody, setNotifBody] = useState('This is a test notification from the Saathira Admin Console.');
  const [notifType, setNotifType] = useState('SYSTEM');
  const [sending, setSending] = useState(false);
  const [resultMsg, setResultMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const res = await adminApi.getUsers(query, roleFilter);
      setUsers(res.items || []);
    } catch (err) {
      console.error('Failed to load users', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [roleFilter]);

  const toggleStatus = async (user: any) => {
    const nextStatus = user.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';
    const confirm = window.confirm(
      `Are you sure you want to change status of ${user.fullName || 'User'} to ${nextStatus}?`
    );
    if (!confirm) return;

    try {
      await adminApi.updateUserStatus(user.id, nextStatus);
      fetchUsers();
    } catch (err: any) {
      alert(`Status update failed: ${err.message}`);
    }
  };

  const openPushModal = (user?: any) => {
    if (user) {
      setSelectedUser(user);
      setTargetMode('USER');
      setNotifTitle(`Hello ${user.fullName?.split(' ')[0] || 'there'}!`);
      setNotifBody('Your Saathira companion booking status has been updated.');
    } else {
      setSelectedUser(null);
      setTargetMode('ALL');
      setNotifTitle('Saathira Platform Notice');
      setNotifBody('New activities and verified companions are now available in your city.');
    }
    setResultMsg(null);
    setModalOpen(true);
  };

  const handleSendPush = async (e: React.FormEvent) => {
    e.preventDefault();
    setSending(true);
    setResultMsg(null);

    const targetId = targetMode === 'ALL' ? 'ALL' : selectedUser?.id;
    if (!targetId) {
      setResultMsg({ type: 'error', text: 'Please select a recipient user.' });
      setSending(false);
      return;
    }

    try {
      const res = await adminApi.sendTestNotification({
        userId: targetId,
        title: notifTitle.trim(),
        body: notifBody.trim(),
        type: notifType,
      });

      setResultMsg({
        type: 'success',
        text: res.message || 'Notification processed successfully!',
      });
    } catch (err: any) {
      setResultMsg({
        type: 'error',
        text: err.message || 'Failed to send notification.',
      });
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="p-8 space-y-6">
      {/* Header & Search */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3 w-full md:w-auto">
          <div className="relative flex-1 md:w-80">
            <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name, phone, city..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && fetchUsers()}
              className="w-full bg-brand-card rounded-xl border border-brand-border pl-10 pr-4 py-2 text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-brand-primary"
            />
          </div>
          <button
            onClick={fetchUsers}
            className="px-4 py-2 rounded-xl bg-brand-primary text-white text-xs font-semibold hover:bg-brand-primaryHover"
          >
            Search
          </button>
        </div>

        <div className="flex items-center gap-3">
          {/* Quick Push Broadcast CTA */}
          <button
            onClick={() => openPushModal()}
            className="flex items-center gap-2 px-3.5 py-2 rounded-xl bg-purple-500/15 border border-purple-500/30 text-purple-300 hover:bg-purple-500 hover:text-white text-xs font-semibold transition-all shadow-sm"
          >
            <Bell className="w-4 h-4" />
            <span>Test Push Notification</span>
          </button>

          <div className="flex items-center gap-2 bg-brand-card p-1 rounded-xl border border-brand-border">
            {[
              { id: '', label: 'All Users' },
              { id: 'CUSTOMER', label: 'Customers' },
              { id: 'COMPANION', label: 'Companions' },
            ].map((r) => (
              <button
                key={r.id}
                onClick={() => setRoleFilter(r.id)}
                className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                  roleFilter === r.id
                    ? 'bg-brand-primary text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                {r.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
              <tr>
                <th className="py-3.5 px-5">User</th>
                <th className="py-3.5 px-5">Role</th>
                <th className="py-3.5 px-5">City</th>
                <th className="py-3.5 px-5">FCM Push Device</th>
                <th className="py-3.5 px-5">Joined</th>
                <th className="py-3.5 px-5">Status</th>
                <th className="py-3.5 px-5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/[0.04]">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400">
                    Loading users...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-400">
                    No users matching criteria
                  </td>
                </tr>
              ) : (
                users.map((u) => {
                  const hasFcm = Boolean(u.fcmToken);

                  return (
                    <tr key={u.id} className="hover:bg-white/[0.02] transition-colors">
                      <td className="py-3.5 px-5">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-brand-primary/20 text-brand-primary font-bold flex items-center justify-center">
                            {u.fullName?.[0]?.toUpperCase() ?? 'U'}
                          </div>
                          <div>
                            <div className="font-semibold text-white flex items-center gap-1.5">
                              <span>{u.fullName ?? 'Unnamed User'}</span>
                              {u.companion?.verificationStatus === 'APPROVED' && (
                                <Shield className="w-3.5 h-3.5 text-emerald-400" />
                              )}
                            </div>
                            <div className="text-[11px] text-slate-400">{u.phone ?? u.email ?? 'No contact'}</div>
                          </div>
                        </div>
                      </td>
                      <td className="py-3.5 px-5">
                        <span
                          className={`px-2 py-0.5 rounded text-[11px] font-semibold ${
                            u.role === 'COMPANION'
                              ? 'bg-purple-500/20 text-purple-300'
                              : 'bg-blue-500/20 text-blue-300'
                          }`}
                        >
                          {u.role}
                        </span>
                      </td>
                      <td className="py-3.5 px-5 text-slate-300">{u.city ?? '—'}</td>
                      <td className="py-3.5 px-5">
                        {hasFcm ? (
                          <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-purple-500/15 text-purple-300 border border-purple-500/30">
                            <Smartphone className="w-3 h-3 text-purple-400" />
                            <span>Registered</span>
                          </div>
                        ) : (
                          <span className="text-[11px] text-slate-500">Not Synced</span>
                        )}
                      </td>
                      <td className="py-3.5 px-5 text-slate-400">
                        {new Date(u.createdAt).toLocaleDateString('en-IN', {
                          day: 'numeric',
                          month: 'short',
                          year: 'numeric',
                        })}
                      </td>
                      <td className="py-3.5 px-5">
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            u.status === 'ACTIVE'
                              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                              : 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                          }`}
                        >
                          {u.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-5 text-right space-x-2">
                        {/* Send Push Action Button */}
                        <button
                          onClick={() => openPushModal(u)}
                          title="Send test push notification to this user"
                          className="px-2.5 py-1 rounded-lg text-xs font-semibold bg-purple-500/15 text-purple-300 hover:bg-purple-500 hover:text-white transition-colors inline-flex items-center gap-1"
                        >
                          <Bell className="w-3 h-3" />
                          <span>Push</span>
                        </button>

                        <button
                          onClick={() => toggleStatus(u)}
                          className={`px-3 py-1 rounded-lg text-xs font-semibold transition-colors ${
                            u.status === 'ACTIVE'
                              ? 'bg-rose-500/10 text-rose-300 hover:bg-rose-500 hover:text-white'
                              : 'bg-emerald-500/10 text-emerald-300 hover:bg-emerald-500 hover:text-white'
                          }`}
                        >
                          {u.status === 'ACTIVE' ? 'Suspend' : 'Activate'}
                        </button>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Push Notification Modal */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-brand-card w-full max-w-lg rounded-2xl border border-brand-border shadow-2xl p-6 space-y-5 animate-in fade-in zoom-in-95 duration-150">
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b border-brand-border pb-4">
              <div className="flex items-center gap-2.5">
                <div className="w-9 h-9 rounded-xl bg-purple-500/20 text-purple-400 flex items-center justify-center">
                  <Bell className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-base text-white">Send Push Notification</h3>
                  <p className="text-xs text-slate-400">Dispatch live alerts via Firebase Cloud Messaging</p>
                </div>
              </div>
              <button
                onClick={() => setModalOpen(false)}
                className="text-slate-400 hover:text-white p-1 rounded-lg hover:bg-white/5 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Recipient Selector / Info */}
            <div className="p-3.5 rounded-xl bg-white/[0.02] border border-brand-border space-y-2">
              <div className="flex items-center justify-between text-xs">
                <span className="text-slate-400 font-medium">Target Recipient:</span>
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setTargetMode('USER')}
                    disabled={!selectedUser}
                    className={`px-2.5 py-1 rounded-lg text-xs font-semibold ${
                      targetMode === 'USER'
                        ? 'bg-brand-primary text-white'
                        : 'text-slate-400 hover:text-white disabled:opacity-30'
                    }`}
                  >
                    Specific User
                  </button>
                  <button
                    type="button"
                    onClick={() => setTargetMode('ALL')}
                    className={`px-2.5 py-1 rounded-lg text-xs font-semibold ${
                      targetMode === 'ALL'
                        ? 'bg-brand-primary text-white'
                        : 'text-slate-400 hover:text-white'
                    }`}
                  >
                    Broadcast to All
                  </button>
                </div>
              </div>

              {targetMode === 'USER' && selectedUser && (
                <div className="flex items-center justify-between pt-2 border-t border-white/[0.04]">
                  <div>
                    <span className="font-bold text-white text-xs">{selectedUser.fullName || 'User'}</span>
                    <span className="text-[11px] text-slate-400 ml-2">({selectedUser.phone || selectedUser.email || selectedUser.role})</span>
                  </div>
                  {selectedUser.fcmToken ? (
                    <span className="text-[10px] text-emerald-400 font-semibold bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">
                      ✓ FCM Token Available
                    </span>
                  ) : (
                    <span className="text-[10px] text-amber-400 font-semibold bg-amber-500/10 px-2 py-0.5 rounded-full border border-amber-500/20">
                      ⚠ No FCM Token (Inbox only)
                    </span>
                  )}
                </div>
              )}

              {targetMode === 'ALL' && (
                <div className="pt-2 border-t border-white/[0.04] text-[11px] text-slate-300">
                  📢 Will dispatch to all active registered users. Those with synced mobile apps will receive an instant push notification on their phone.
                </div>
              )}
            </div>

            {/* Notification Form */}
            <form onSubmit={handleSendPush} className="space-y-4 text-xs">
              <div>
                <label className="block text-slate-300 font-semibold mb-1.5">Notification Title</label>
                <input
                  type="text"
                  required
                  value={notifTitle}
                  onChange={(e) => setNotifTitle(e.target.value)}
                  placeholder="e.g. Booking Confirmed!"
                  className="w-full bg-brand-dark rounded-xl border border-brand-border px-3.5 py-2.5 text-white placeholder:text-slate-500 focus:outline-none focus:border-brand-primary"
                />
              </div>

              <div>
                <label className="block text-slate-300 font-semibold mb-1.5">Message Body</label>
                <textarea
                  rows={3}
                  required
                  value={notifBody}
                  onChange={(e) => setNotifBody(e.target.value)}
                  placeholder="Type notification message here..."
                  className="w-full bg-brand-dark rounded-xl border border-brand-border p-3.5 text-white placeholder:text-slate-500 focus:outline-none focus:border-brand-primary"
                />
              </div>

              <div>
                <label className="block text-slate-300 font-semibold mb-1.5">Category / Type</label>
                <select
                  value={notifType}
                  onChange={(e) => setNotifType(e.target.value)}
                  className="w-full bg-brand-dark rounded-xl border border-brand-border px-3.5 py-2.5 text-white focus:outline-none focus:border-brand-primary"
                >
                  <option value="SYSTEM">System Alert</option>
                  <option value="BOOKING_CONFIRMED">Booking Confirmed</option>
                  <option value="BOOKING_REQUEST">Booking Request</option>
                  <option value="PAYMENT_RECEIVED">Payment Received</option>
                  <option value="SAFETY_ALERT">Safety Alert</option>
                  <option value="VERIFICATION_APPROVED">Verification Approved</option>
                </select>
              </div>

              {/* Status Result Message */}
              {resultMsg && (
                <div
                  className={`p-3 rounded-xl border flex items-start gap-2.5 text-xs ${
                    resultMsg.type === 'success'
                      ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300'
                      : 'bg-rose-500/10 border-rose-500/30 text-rose-300'
                  }`}
                >
                  {resultMsg.type === 'success' ? (
                    <CheckCircle2 className="w-4 h-4 shrink-0 mt-0.5 text-emerald-400" />
                  ) : (
                    <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-rose-400" />
                  )}
                  <span className="leading-relaxed">{resultMsg.text}</span>
                </div>
              )}

              {/* Action Buttons */}
              <div className="flex items-center justify-end gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setModalOpen(false)}
                  className="px-4 py-2.5 rounded-xl border border-brand-border text-slate-300 hover:text-white hover:bg-white/5 transition-colors font-semibold"
                >
                  Close
                </button>
                <button
                  type="submit"
                  disabled={sending}
                  className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-brand-primary text-white font-semibold hover:bg-brand-primaryHover disabled:opacity-50 transition-all shadow-md shadow-purple-600/30"
                >
                  <Send className="w-4 h-4" />
                  <span>{sending ? 'Dispatching...' : 'Send Push Notification'}</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
