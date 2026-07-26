import { useState } from 'react';
import { apiClient, messageFrom } from '../api/client';
import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

const STATUSES = ['requested', 'assigned', 'in_progress', 'completed', 'cancelled'];

interface AdminConciergeOrder {
  id: string;
  orderType: string;
  status: string;
  createdAt: string;
  customer: { fullName: string };
  assignedPartner: { businessName: string } | null;
}

export function ConciergePage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [actionError, setActionError] = useState<string | null>(null);
  const { data, loading, error } = useFetch<AdminConciergeOrder[]>('/admin/concierge-orders', [refreshKey]);

  const updateStatus = async (id: string, status: string) => {
    setActionError(null);
    try {
      await apiClient.patch(`/admin/concierge-orders/${id}`, { status });
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  return (
    <div>
      <h2 className="page-title">Concierge Orders</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {(error || actionError) && <p className="error-note">{error ?? actionError}</p>}
      {data && data.length === 0 && <p className="empty-note">No concierge orders yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Type</th>
              <th>Customer</th>
              <th>Assigned partner</th>
              <th>Created</th>
              <th>Status</th>
              <th>Update</th>
            </tr>
          </thead>
          <tbody>
            {data.map((o) => (
              <tr key={o.id}>
                <td>{o.orderType.replace(/_/g, ' ')}</td>
                <td>{o.customer.fullName}</td>
                <td>{o.assignedPartner?.businessName ?? '—'}</td>
                <td>{new Date(o.createdAt).toLocaleString()}</td>
                <td><StatusBadge status={o.status} /></td>
                <td>
                  <select value={o.status} onChange={(e) => updateStatus(o.id, e.target.value)}>
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
