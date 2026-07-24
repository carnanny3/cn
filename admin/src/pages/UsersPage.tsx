import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

interface AdminUser {
  id: string;
  fullName: string;
  phoneNumber: string | null;
  email: string;
  status: string;
  accountType: string;
  emirate: string | null;
  createdAt: string;
}

export function UsersPage() {
  const { data, loading, error } = useFetch<AdminUser[]>('/admin/users');

  return (
    <div>
      <h2 className="page-title">Users</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {error && <p className="error-note">{error}</p>}
      {data && data.length === 0 && <p className="empty-note">No customers registered yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Name</th>
              <th>Email</th>
              <th>Phone</th>
              <th>Emirate</th>
              <th>Account type</th>
              <th>Status</th>
              <th>Joined</th>
            </tr>
          </thead>
          <tbody>
            {data.map((u) => (
              <tr key={u.id}>
                <td>{u.fullName}</td>
                <td>{u.email}</td>
                <td>{u.phoneNumber ?? '—'}</td>
                <td>{u.emirate ?? '—'}</td>
                <td>{u.accountType}</td>
                <td><StatusBadge status={u.status} /></td>
                <td>{new Date(u.createdAt).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
