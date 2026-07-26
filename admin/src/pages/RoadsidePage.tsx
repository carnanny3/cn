import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

interface AdminRoadsideRequest {
  id: string;
  serviceType: string;
  status: string;
  requestedAt: string;
  customer: { fullName: string };
  provider: { businessName: string } | null;
}

export function RoadsidePage() {
  const { data, loading, error } = useFetch<AdminRoadsideRequest[]>('/admin/roadside-requests');

  return (
    <div>
      <h2 className="page-title">Roadside Assistance</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {error && <p className="error-note">{error}</p>}
      {data && data.length === 0 && <p className="empty-note">No roadside requests yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Service</th>
              <th>Customer</th>
              <th>Provider</th>
              <th>Requested</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {data.map((r) => (
              <tr key={r.id}>
                <td>{r.serviceType.replace(/_/g, ' ')}</td>
                <td>{r.customer.fullName}</td>
                <td>{r.provider?.businessName ?? '—'}</td>
                <td>{new Date(r.requestedAt).toLocaleString()}</td>
                <td><StatusBadge status={r.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
