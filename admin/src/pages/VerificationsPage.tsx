import React, { useState, useEffect } from 'react';
import { ShieldCheck, Check, X, ExternalLink, FileText, Image as ImageIcon } from 'lucide-react';
import { adminApi } from '../api/client';

export const VerificationsPage: React.FC = () => {
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('PENDING');
  const [selectedItem, setSelectedItem] = useState<any | null>(null);
  const [actionNote, setActionNote] = useState('');
  const [processing, setProcessing] = useState(false);

  const fetchItems = async () => {
    setLoading(true);
    try {
      const res = await adminApi.getVerifications(filter === 'ALL' ? undefined : filter);
      setItems(res.items || []);
    } catch (err) {
      console.error('Failed to load verifications', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchItems();
  }, [filter]);

  const handleApprove = async (id: string) => {
    setProcessing(true);
    try {
      await adminApi.approveVerification(id, actionNote || 'Verified successfully');
      setSelectedItem(null);
      setActionNote('');
      fetchItems();
    } catch (err: any) {
      alert(`Approval failed: ${err.message}`);
    } finally {
      setProcessing(false);
    }
  };

  const handleReject = async (id: string) => {
    if (!actionNote.trim()) {
      alert('Please provide a reason for rejecting the ID document');
      return;
    }
    setProcessing(true);
    try {
      await adminApi.rejectVerification(id, actionNote);
      setSelectedItem(null);
      setActionNote('');
      fetchItems();
    } catch (err: any) {
      alert(`Rejection failed: ${err.message}`);
    } finally {
      setProcessing(false);
    }
  };

  return (
    <div className="p-8 space-y-6">
      {/* Filter Tabs */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2 bg-brand-card p-1 rounded-xl border border-brand-border">
          {['PENDING', 'APPROVED', 'REJECTED', 'ALL'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
                filter === f
                  ? 'bg-brand-primary text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              {f}
            </button>
          ))}
        </div>
        <span className="text-xs text-slate-400">{items.length} records found</span>
      </div>

      {/* Table */}
      <div className="bg-brand-card rounded-2xl border border-brand-border overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-white/[0.02] text-slate-400 uppercase tracking-wider font-semibold border-b border-brand-border">
              <tr>
                <th className="py-3.5 px-5">Companion</th>
                <th className="py-3.5 px-5">City</th>
                <th className="py-3.5 px-5">Document Type</th>
                <th className="py-3.5 px-5">Submitted At</th>
                <th className="py-3.5 px-5">Status</th>
                <th className="py-3.5 px-5 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/[0.04]">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    Loading verification requests...
                  </td>
                </tr>
              ) : items.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-8 text-center text-slate-400">
                    No verifications found in this category
                  </td>
                </tr>
              ) : (
                items.map((item) => {
                  const comp = item.companion;
                  const user = comp?.user;

                  return (
                    <tr key={item.id} className="hover:bg-white/[0.02] transition-colors">
                      <td className="py-3.5 px-5">
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-full bg-brand-primary/20 text-brand-primary font-bold flex items-center justify-center">
                            {user?.fullName?.[0]?.toUpperCase() ?? 'C'}
                          </div>
                          <div>
                            <div className="font-semibold text-white">{user?.fullName ?? 'Companion'}</div>
                            <div className="text-[11px] text-slate-400">{user?.phone ?? 'No phone'}</div>
                          </div>
                        </div>
                      </td>
                      <td className="py-3.5 px-5 text-slate-300">{user?.city ?? 'India'}</td>
                      <td className="py-3.5 px-5">
                        <span className="px-2 py-0.5 rounded bg-white/[0.06] text-slate-300 font-mono text-[11px]">
                          {item.documentType}
                        </span>
                      </td>
                      <td className="py-3.5 px-5 text-slate-400">
                        {new Date(item.createdAt).toLocaleDateString('en-IN', {
                          day: 'numeric',
                          month: 'short',
                          year: 'numeric',
                        })}
                      </td>
                      <td className="py-3.5 px-5">
                        <span
                          className={`px-2.5 py-0.5 rounded-full text-[11px] font-bold ${
                            item.status === 'APPROVED'
                              ? 'bg-emerald-500/20 text-emerald-300 border border-emerald-500/30'
                              : item.status === 'PENDING'
                              ? 'bg-amber-500/20 text-amber-300 border border-amber-500/30'
                              : 'bg-rose-500/20 text-rose-300 border border-rose-500/30'
                          }`}
                        >
                          {item.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-5 text-right">
                        <button
                          onClick={() => setSelectedItem(item)}
                          className="px-3 py-1.5 rounded-lg bg-brand-primary/20 text-brand-primary hover:bg-brand-primary hover:text-white font-semibold text-xs transition-colors"
                        >
                          Review ID
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

      {/* Review Modal */}
      {selectedItem && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-sm flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-brand-card w-full max-w-2xl rounded-2xl border border-brand-border p-6 space-y-5 shadow-2xl my-8">
            <div className="flex items-center justify-between border-b border-brand-border pb-4">
              <div className="flex items-center gap-2.5">
                <ShieldCheck className="w-5 h-5 text-brand-primary" />
                <h3 className="font-bold text-white text-base">Identity Verification Review</h3>
              </div>
              <button
                onClick={() => setSelectedItem(null)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-2 gap-3 text-xs bg-brand-dark/50 p-3.5 rounded-xl border border-white/[0.04]">
              <div>
                <span className="text-slate-400 block text-[11px]">Applicant</span>
                <span className="font-bold text-white text-sm">{selectedItem.companion?.user?.fullName}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Phone & City</span>
                <span className="text-slate-200">
                  {selectedItem.companion?.user?.phone} • {selectedItem.companion?.user?.city || 'Not specified'}
                </span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Document Type</span>
                <span className="font-mono text-purple-300 font-semibold">{selectedItem.documentType}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[11px]">Storage Path</span>
                <span className="font-mono text-slate-400 truncate block text-[11px]" title={selectedItem.documentPath}>
                  {selectedItem.documentPath}
                </span>
              </div>
            </div>

            {/* Document & Selfie Image Previews */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {/* Document Image Preview */}
              <div className="bg-brand-dark/80 rounded-xl border border-brand-border p-3 space-y-2">
                <div className="flex items-center justify-between text-xs font-semibold text-slate-300">
                  <div className="flex items-center gap-1.5">
                    <ImageIcon className="w-4 h-4 text-brand-primary" />
                    <span>Government ID Document</span>
                  </div>
                  {selectedItem.documentUrl && (
                    <a
                      href={selectedItem.documentUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-[11px] text-brand-primary hover:underline flex items-center gap-1"
                    >
                      <span>Full View</span>
                      <ExternalLink className="w-3 h-3" />
                    </a>
                  )}
                </div>

                {selectedItem.documentUrl ? (
                  selectedItem.documentUrl.toLowerCase().includes('.pdf') ? (
                    <div className="h-44 flex flex-col items-center justify-center bg-black/30 rounded-lg border border-dashed border-white/10 text-slate-400 gap-2">
                      <FileText className="w-10 h-10 text-brand-primary" />
                      <span className="text-xs">PDF Document</span>
                      <a
                        href={selectedItem.documentUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="px-3 py-1 bg-brand-primary/20 text-brand-primary text-xs rounded hover:bg-brand-primary hover:text-white transition-colors"
                      >
                        Open PDF File
                      </a>
                    </div>
                  ) : (
                    <div className="relative group rounded-lg overflow-hidden border border-white/10 bg-black/40 h-44 flex items-center justify-center">
                      <img
                        src={selectedItem.documentUrl}
                        alt="KYC Document"
                        className="w-full h-full object-contain"
                        onError={(e) => {
                          (e.currentTarget as HTMLElement).style.display = 'none';
                        }}
                      />
                    </div>
                  )
                ) : (
                  <div className="h-44 flex flex-col items-center justify-center bg-black/30 rounded-lg border border-dashed border-white/10 text-slate-500 text-xs">
                    <span>No image uploaded or path invalid</span>
                  </div>
                )}
              </div>

              {/* Selfie Image Preview */}
              <div className="bg-brand-dark/80 rounded-xl border border-brand-border p-3 space-y-2">
                <div className="flex items-center justify-between text-xs font-semibold text-slate-300">
                  <div className="flex items-center gap-1.5">
                    <ImageIcon className="w-4 h-4 text-emerald-400" />
                    <span>Applicant Selfie (Face Match)</span>
                  </div>
                  {selectedItem.selfieUrl && (
                    <a
                      href={selectedItem.selfieUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-[11px] text-emerald-400 hover:underline flex items-center gap-1"
                    >
                      <span>Full View</span>
                      <ExternalLink className="w-3 h-3" />
                    </a>
                  )}
                </div>

                {selectedItem.selfieUrl ? (
                  <div className="relative group rounded-lg overflow-hidden border border-white/10 bg-black/40 h-44 flex items-center justify-center">
                    <img
                      src={selectedItem.selfieUrl}
                      alt="Applicant Selfie"
                      className="w-full h-full object-contain"
                      onError={(e) => {
                        (e.currentTarget as HTMLElement).style.display = 'none';
                      }}
                    />
                  </div>
                ) : (
                  <div className="h-44 flex flex-col items-center justify-center bg-black/30 rounded-lg border border-dashed border-white/10 text-slate-500 text-xs">
                    <span>Selfie not submitted</span>
                  </div>
                )}
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-300">Admin Review Notes</label>
              <textarea
                value={actionNote}
                onChange={(e) => setActionNote(e.target.value)}
                placeholder="Reason or notes (required if rejecting)..."
                rows={3}
                className="w-full bg-brand-dark rounded-xl border border-brand-border p-3 text-xs text-slate-200 placeholder:text-slate-500 focus:outline-none focus:border-brand-primary"
              />
            </div>

            <div className="flex items-center gap-3 pt-2">
              <button
                onClick={() => handleReject(selectedItem.id)}
                disabled={processing}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl border border-rose-500/40 bg-rose-500/10 text-rose-300 hover:bg-rose-500 hover:text-white font-bold text-xs transition-colors disabled:opacity-50"
              >
                <X className="w-4 h-4" />
                <span>Reject ID</span>
              </button>
              <button
                onClick={() => handleApprove(selectedItem.id)}
                disabled={processing}
                className="flex-1 flex items-center justify-center gap-2 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-xs shadow-lg shadow-emerald-600/30 transition-colors disabled:opacity-50"
              >
                <Check className="w-4 h-4" />
                <span>Approve & Verify</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
