import { useState } from 'react';
import { apiClient, messageFrom } from '../api/client';
import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

const STATUSES = ['open', 'in_progress', 'resolved', 'closed'];

interface AdminTicket {
  id: string;
  subject: string;
  category: string;
  status: string;
  createdAt: string;
  user: { fullName: string; email: string | null };
}

export function SupportPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [actionError, setActionError] = useState<string | null>(null);
  const { data, loading, error } = useFetch<AdminTicket[]>('/admin/support-tickets', [refreshKey]);

  const updateStatus = async (id: string, status: string) => {
    setActionError(null);
    try {
      await apiClient.patch(`/admin/support-tickets/${id}/status`, { status });
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  return (
    <div>
      <h2 className="page-title">Support Tickets</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {(error || actionError) && <p className="error-note">{error ?? actionError}</p>}
      {data && data.length === 0 && <p className="empty-note">No support tickets yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Subject</th>
              <th>Category</th>
              <th>Customer</th>
              <th>Created</th>
              <th>Status</th>
              <th>Update</th>
            </tr>
          </thead>
          <tbody>
            {data.map((t) => (
              <tr key={t.id}>
                <td>{t.subject}</td>
                <td>{t.category}</td>
                <td>{t.user.fullName}</td>
                <td>{new Date(t.createdAt).toLocaleString()}</td>
                <td><StatusBadge status={t.status} /></td>
                <td>
                  <select value={t.status} onChange={(e) => updateStatus(t.id, e.target.value)}>
                    {STATUSES.map((s) => (
                      <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
                    ))}
                  </select>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
