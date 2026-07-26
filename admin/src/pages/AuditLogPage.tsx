import { useFetch } from '../api/useFetch';

interface AuditLogEntry {
  id: string;
  adminUserId: string;
  action: string;
  entityType: string;
  entityId: string;
  ipAddress: string | null;
  createdAt: string;
}

export function AuditLogPage() {
  const { data, loading, error } = useFetch<AuditLogEntry[]>('/admin/audit-log');

  return (
    <div>
      <h2 className="page-title">Audit Log</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {error && <p className="error-note">{error}</p>}
      {data && data.length === 0 && <p className="empty-note">No admin actions recorded yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>When</th>
              <th>Admin user</th>
              <th>Action</th>
              <th>Entity</th>
              <th>IP</th>
            </tr>
          </thead>
          <tbody>
            {data.map((e) => (
              <tr key={e.id}>
                <td>{new Date(e.createdAt).toLocaleString()}</td>
                <td>{e.adminUserId}</td>
                <td>{e.action}</td>
                <td>{e.entityType} · {e.entityId}</td>
                <td>{e.ipAddress ?? '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
