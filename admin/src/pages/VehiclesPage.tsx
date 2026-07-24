import { useFetch } from '../api/useFetch';

interface AdminVehicle {
  id: string;
  make: string;
  model: string;
  year: number;
  plateNumber: string;
  healthScore: number | null;
  owners: { user: { fullName: string; phoneNumber: string } }[];
}

export function VehiclesPage() {
  const { data, loading, error } = useFetch<AdminVehicle[]>('/admin/vehicles');

  return (
    <div>
      <h2 className="page-title">Vehicles</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {error && <p className="error-note">{error}</p>}
      {data && data.length === 0 && <p className="empty-note">No vehicles registered yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Vehicle</th>
              <th>Plate</th>
              <th>Owner</th>
              <th>Health Score</th>
            </tr>
          </thead>
          <tbody>
            {data.map((v) => (
              <tr key={v.id}>
                <td>{v.year} {v.make} {v.model}</td>
                <td>{v.plateNumber}</td>
                <td>{v.owners[0]?.user.fullName ?? '—'}</td>
                <td>{v.healthScore ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
