export const API_BASE = '/api/v1';

export async function adminFetch<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = localStorage.getItem('saathira_admin_token');
  const headers = new Headers(options.headers || {});
  headers.set('Content-Type', 'application/json');

  if (token) {
    headers.set('Authorization', `Bearer ${token}`);
  }

  const res = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  });

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}));
    throw new Error(errorData.message || `Request failed with status ${res.status}`);
  }

  return res.json();
}

export const adminApi = {
  getStats: () => adminFetch<any>('/admin/dashboard/stats'),
  getVerifications: (status?: string) =>
    adminFetch<any>(`/admin/verifications${status ? `?status=${status}` : ''}`),
  approveVerification: (id: string, note?: string) =>
    adminFetch<any>(`/admin/verifications/${id}/approve`, {
      method: 'POST',
      body: JSON.stringify({ note }),
    }),
  rejectVerification: (id: string, note?: string) =>
    adminFetch<any>(`/admin/verifications/${id}/reject`, {
      method: 'POST',
      body: JSON.stringify({ note }),
    }),
  getUsers: (query?: string, role?: string) =>
    adminFetch<any>(`/admin/users?${new URLSearchParams({ query: query || '', status: role || '' })}`),
  updateUserStatus: (id: string, status: string) =>
    adminFetch<any>(`/admin/users/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status }),
    }),
  getBookings: (status?: string) =>
    adminFetch<any>(`/admin/bookings${status ? `?status=${status}` : ''}`),
  getPayments: () => adminFetch<any>('/admin/payments'),
  getPayouts: () => adminFetch<any>('/admin/payouts'),
  approvePayout: (id: string) =>
    adminFetch<any>(`/admin/payouts/${id}/approve`, { method: 'POST' }),
  getReports: (status?: string) =>
    adminFetch<any>(`/admin/reports${status ? `?status=${status}` : ''}`),
  resolveReport: (id: string, note: string, suspendUser?: boolean) =>
    adminFetch<any>(`/admin/reports/${id}/resolve`, {
      method: 'PATCH',
      body: JSON.stringify({ resolutionNote: note, suspendUser }),
    }),
  getDisputes: () => adminFetch<any>('/admin/disputes'),
  resolveDispute: (id: string, resolution: string, refundCustomer?: boolean) =>
    adminFetch<any>(`/admin/disputes/${id}/resolve`, {
      method: 'PATCH',
      body: JSON.stringify({ resolution, refundCustomer }),
    }),
  getAuditLogs: () => adminFetch<any>('/admin/audit-logs'),
  sendTestNotification: (dto: { userId: string; title: string; body: string; type?: string }) =>
    adminFetch<any>('/admin/notifications/test', {
      method: 'POST',
      body: JSON.stringify(dto),
    }),
};
