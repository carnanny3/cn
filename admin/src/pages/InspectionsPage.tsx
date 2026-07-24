import { useState } from 'react';
import { apiClient, messageFrom } from '../api/client';
import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

interface AdminInspection {
  id: string;
  status: string;
  scheduledAt: string;
  priceAmount: number;
  vehicle: { make: string; model: string; year: number } | null;
  rawMakeModelYear: string | null;
  requester: { fullName: string; phoneNumber: string };
  report: { overallScore: number; overallStatus: string; aiRecommendation: string } | null;
}

export function InspectionsPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [actionError, setActionError] = useState<string | null>(null);
  const { data, loading, error } = useFetch<AdminInspection[]>('/admin/inspections', [refreshKey]);

  const approveReport = async (id: string) => {
    setActionError(null);
    try {
      await apiClient.patch(`/inspections/${id}/approve-report`, {});
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  return (
    <div>
      <h2 className="page-title">Inspections</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {(error || actionError) && <p className="error-note">{error ?? actionError}</p>}
      {data && data.length === 0 && <p className="empty-note">No inspections booked yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Vehicle</th>
              <th>Requester</th>
              <th>Scheduled</th>
              <th>Status</th>
              <th>Report</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {data.map((i) => (
              <tr key={i.id}>
                <td>{i.vehicle ? `${i.vehicle.year} ${i.vehicle.make} ${i.vehicle.model}` : i.rawMakeModelYear ?? '—'}</td>
                <td>{i.requester.fullName}</td>
                <td>{new Date(i.scheduledAt).toLocaleString()}</td>
                <td><StatusBadge status={i.status} /></td>
                <td>
                  {i.report ? (
                    <span>
                      {i.report.overallScore}/10 · {i.report.aiRecommendation.replace(/_/g, ' ')}
                    </span>
                  ) : (
                    '—'
                  )}
                </td>
                <td>
                  {i.status === 'qa_review' && (
                    <button onClick={() => approveReport(i.id)}>Approve report</button>
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
