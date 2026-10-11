import React, { useState, useEffect } from 'react';
import { adminApi } from '../api/client';

export const AuditLogsPage: React.FC = () => {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchLogs = async () => {
    setLoading(true);
    try {
      const res = await adminApi.getAuditLogs();
      setLogs(res.items || []);
    } catch (err) {
      console.error('Failed to load audit logs', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchLogs();
  }, []);

  return (
    <div className="p-8 space-y-6">
      <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
              <tr>
                <th className="py-3.5 px-5">Timestamp</th>
                <th className="py-3.5 px-5">Admin Actor ID</th>
                <th className="py-3.5 px-5">Action Performed</th>
                <th className="py-3.5 px-5">Target Entity</th>
                <th className="py-3.5 px-5">Entity ID</th>
                <th className="py-3.5 px-5">Metadata Details</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/[0.04]">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    Loading audit trail...
                  </td>
                </tr>
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    No audit records logged yet
                  </td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-white/[0.02] transition-colors">
                    <td className="py-3.5 px-5 text-slate-400">
                      {new Date(log.createdAt).toLocaleDateString('en-IN', {
                        day: 'numeric',
                        month: 'short',
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit',
                      })}
                    </td>
                    <td className="py-3.5 px-5 font-mono text-slate-300 truncate max-w-[120px]">
                      {log.actorId}
                    </td>
                    <td className="py-3.5 px-5 font-bold text-purple-300">{log.action}</td>
                    <td className="py-3.5 px-5 text-slate-300">{log.entityType}</td>
                    <td className="py-3.5 px-5 font-mono text-[11px] text-slate-400 truncate max-w-[120px]">
                      {log.entityId}
                    </td>
                    <td className="py-3.5 px-5 font-mono text-[10px] text-slate-400 max-w-[200px] truncate">
                      {JSON.stringify(log.metadata)}
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
