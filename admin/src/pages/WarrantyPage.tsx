import { useState } from 'react';
import { apiClient, messageFrom } from '../api/client';
import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

const STATUSES = [
  'submitted',
  'under_review',
  'inspection_required',
  'approved',
  'rejected',
  'repair_authorized',
  'completed',
  'closed',
];

interface AdminClaim {
  id: string;
  description: string;
  status: string;
  createdAt: string;
  policy: { customer: { fullName: string }; plan: { name: string } };
}

export function WarrantyPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [actionError, setActionError] = useState<string | null>(null);
  const { data, loading, error } = useFetch<AdminClaim[]>('/admin/warranty-claims', [refreshKey]);

  const updateStatus = async (id: string, status: string) => {
    setActionError(null);
    try {
      await apiClient.patch(`/admin/warranty-claims/${id}/status`, { status });
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  return (
    <div>
      <h2 className="page-title">Warranty Claims</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {(error || actionError) && <p className="error-note">{error ?? actionError}</p>}
      {data && data.length === 0 && <p className="empty-note">No warranty claims yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Plan</th>
              <th>Customer</th>
              <th>Description</th>
              <th>Filed</th>
              <th>Status</th>
              <th>Update</th>
            </tr>
          </thead>
          <tbody>
            {data.map((c) => (
              <tr key={c.id}>
                <td>{c.policy.plan.name}</td>
                <td>{c.policy.customer.fullName}</td>
                <td>{c.description}</td>
                <td>{new Date(c.createdAt).toLocaleString()}</td>
                <td><StatusBadge status={c.status} /></td>
                <td>
                  <select value={c.status} onChange={(e) => updateStatus(c.id, e.target.value)}>
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
