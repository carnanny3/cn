import { useFetch } from '../api/useFetch';

interface Summary {
  userCount: number;
  vehicleCount: number;
  pendingPartners: number;
  qaQueueCount: number;
  activeBookings: number;
}

export function OverviewPage() {
  const { data, loading, error } = useFetch<Summary>('/admin/summary');

  if (loading) return <p className="empty-note">Loading...</p>;
  if (error) return <p className="error-note">{error}</p>;
  if (!data) return null;

  const cards = [
    { label: 'Customers', value: data.userCount },
    { label: 'Vehicles in Garage', value: data.vehicleCount },
    { label: 'Pending Partner Verifications', value: data.pendingPartners },
    { label: 'Inspections in QA Queue', value: data.qaQueueCount },
    { label: 'Active Bookings', value: data.activeBookings },
  ];

  return (
    <div>
      <h2 className="page-title">Overview</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 16 }}>
        {cards.map((c) => (
          <div key={c.label} style={{ border: '1px solid var(--border)', borderRadius: 12, padding: 20 }}>
            <div style={{ fontSize: 28, fontWeight: 600 }}>{c.value}</div>
            <div style={{ color: 'var(--text-secondary)', fontSize: 13 }}>{c.label}</div>
          </div>
        ))}
      </div>
    </div>
  );
}
