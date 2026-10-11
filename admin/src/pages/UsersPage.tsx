import React, { useState, useEffect } from 'react';
import { Search, Shield } from 'lucide-react';
import { adminApi } from '../api/client';

export const UsersPage: React.FC = () => {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [query, setQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState('');

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

      {/* Users Table */}
      <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
              <tr>
                <th className="py-3.5 px-5">User</th>
                <th className="py-3.5 px-5">Role</th>
                <th className="py-3.5 px-5">City</th>
                <th className="py-3.5 px-5">Joined</th>
                <th className="py-3.5 px-5">Status</th>
                <th className="py-3.5 px-5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/[0.04]">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    Loading users...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    No users matching criteria
                  </td>
                </tr>
              ) : (
                users.map((u) => (
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
                    <td className="py-3.5 px-5 text-right">
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
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
