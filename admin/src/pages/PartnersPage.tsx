import { useState } from 'react';
import { apiClient, messageFrom } from '../api/client';
import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

interface AdminPartner {
  id: string;
  businessName: string;
  partnerType: string;
  status: string;
  ratingAvg: number;
  cancellationRate: number;
  createdAt: string;
}

export function PartnersPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [actionError, setActionError] = useState<string | null>(null);
  const { data, loading, error } = useFetch<AdminPartner[]>('/admin/partners', [refreshKey]);

  const verify = async (id: string, approve: boolean) => {
    setActionError(null);
    try {
      await apiClient.patch(`/partners/${id}/verify`, { approve });
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  return (
    <div>
      <h2 className="page-title">Partners</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {(error || actionError) && <p className="error-note">{error ?? actionError}</p>}
      {data && data.length === 0 && <p className="empty-note">No partners registered yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Business</th>
              <th>Type</th>
              <th>Status</th>
              <th>Rating</th>
              <th>Cancellation rate</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {data.map((p) => (
              <tr key={p.id}>
                <td>{p.businessName}</td>
                <td>{p.partnerType}</td>
                <td><StatusBadge status={p.status} /></td>
                <td>{p.ratingAvg.toFixed(1)}</td>
                <td>{(p.cancellationRate * 100).toFixed(0)}%</td>
                <td>
                  {p.status === 'pending' && (
                    <div style={{ display: 'flex', gap: 8 }}>
                      <button onClick={() => verify(p.id, true)}>Approve</button>
                      <button className="secondary" onClick={() => verify(p.id, false)}>Reject</button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
