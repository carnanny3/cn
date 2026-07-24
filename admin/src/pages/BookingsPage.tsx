import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

interface AdminBooking {
  id: string;
  bookingType: string;
  status: string;
  scheduledAt: string;
  totalAmount: number;
  currency: string;
  vehicle: { make: string; model: string; year: number };
  customer: { fullName: string };
  partner: { businessName: string } | null;
}

export function BookingsPage() {
  const { data, loading, error } = useFetch<AdminBooking[]>('/admin/bookings');

  return (
    <div>
      <h2 className="page-title">Bookings</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {error && <p className="error-note">{error}</p>}
      {data && data.length === 0 && <p className="empty-note">No bookings yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Type</th>
              <th>Vehicle</th>
              <th>Customer</th>
              <th>Partner</th>
              <th>Scheduled</th>
              <th>Amount</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {data.map((b) => (
              <tr key={b.id}>
                <td>{b.bookingType}</td>
                <td>{b.vehicle.year} {b.vehicle.make} {b.vehicle.model}</td>
                <td>{b.customer.fullName}</td>
                <td>{b.partner?.businessName ?? '—'}</td>
                <td>{new Date(b.scheduledAt).toLocaleString()}</td>
                <td>{b.currency} {b.totalAmount.toFixed(0)}</td>
                <td><StatusBadge status={b.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
