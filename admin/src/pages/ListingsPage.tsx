import { useState } from 'react';
import { apiClient, messageFrom } from '../api/client';
import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

const STATUSES = ['draft', 'active', 'reserved', 'sold', 'withdrawn'];

interface AdminListing {
  id: string;
  make: string;
  model: string;
  year: number;
  sellerType: string;
  askingPrice: number;
  status: string;
  createdAt: string;
}

export function ListingsPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [actionError, setActionError] = useState<string | null>(null);
  const { data, loading, error } = useFetch<AdminListing[]>('/admin/listings', [refreshKey]);

  const updateStatus = async (id: string, status: string) => {
    setActionError(null);
    try {
      await apiClient.patch(`/admin/listings/${id}/status`, { status });
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  return (
    <div>
      <h2 className="page-title">Buy-a-Car Listings</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {(error || actionError) && <p className="error-note">{error ?? actionError}</p>}
      {data && data.length === 0 && <p className="empty-note">No listings yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Vehicle</th>
              <th>Seller</th>
              <th>Price</th>
              <th>Listed</th>
              <th>Status</th>
              <th>Update</th>
            </tr>
          </thead>
          <tbody>
            {data.map((l) => (
              <tr key={l.id}>
                <td>{l.year} {l.make} {l.model}</td>
                <td>{l.sellerType}</td>
                <td>AED {l.askingPrice.toFixed(0)}</td>
                <td>{new Date(l.createdAt).toLocaleString()}</td>
                <td><StatusBadge status={l.status} /></td>
                <td>
                  <select value={l.status} onChange={(e) => updateStatus(l.id, e.target.value)}>
                    {STATUSES.map((s) => (
                      <option key={s} value={s}>{s}</option>
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
