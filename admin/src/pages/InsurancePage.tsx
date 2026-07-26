import { useState } from 'react';
import { apiClient, messageFrom } from '../api/client';
import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

interface AdminQuote {
  id: string;
  status: string;
  premiumAmount: number | null;
  coverageType: string | null;
  createdAt: string;
  customer: { fullName: string };
  provider: { name: string };
}

export function InsurancePage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [actionError, setActionError] = useState<string | null>(null);
  const [respondingId, setRespondingId] = useState<string | null>(null);
  const [premiumAmount, setPremiumAmount] = useState('');
  const [coverageType, setCoverageType] = useState('comprehensive');
  const [excessAmount, setExcessAmount] = useState('');
  const [validUntil, setValidUntil] = useState('');
  const { data, loading, error } = useFetch<AdminQuote[]>('/admin/insurance-quotes', [refreshKey]);

  const submitResponse = async (id: string) => {
    setActionError(null);
    try {
      await apiClient.patch(`/admin/insurance-quotes/${id}/respond`, {
        premiumAmount: Number(premiumAmount),
        coverageType,
        excessAmount: Number(excessAmount),
        validUntil: new Date(validUntil).toISOString(),
      });
      setRespondingId(null);
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  return (
    <div>
      <h2 className="page-title">Insurance Quotes</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {(error || actionError) && <p className="error-note">{error ?? actionError}</p>}
      {data && data.length === 0 && <p className="empty-note">No insurance quote requests yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Customer</th>
              <th>Provider</th>
              <th>Coverage</th>
              <th>Premium</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {data.map((q) => (
              <tr key={q.id}>
                <td>{q.customer.fullName}</td>
                <td>{q.provider.name}</td>
                <td>{q.coverageType ?? '—'}</td>
                <td>{q.premiumAmount != null ? `AED ${q.premiumAmount.toFixed(0)}` : '—'}</td>
                <td><StatusBadge status={q.status} /></td>
                <td>
                  {q.status === 'requested' && respondingId !== q.id && (
                    <button onClick={() => setRespondingId(q.id)}>Respond</button>
                  )}
                  {respondingId === q.id && (
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, minWidth: 200 }}>
                      <input placeholder="Premium (AED)" value={premiumAmount} onChange={(e) => setPremiumAmount(e.target.value)} />
                      <select value={coverageType} onChange={(e) => setCoverageType(e.target.value)}>
                        <option value="comprehensive">Comprehensive</option>
                        <option value="third_party_liability">Third-party liability</option>
                      </select>
                      <input placeholder="Excess (AED)" value={excessAmount} onChange={(e) => setExcessAmount(e.target.value)} />
                      <input type="date" value={validUntil} onChange={(e) => setValidUntil(e.target.value)} />
                      <div style={{ display: 'flex', gap: 8 }}>
                        <button onClick={() => submitResponse(q.id)}>Send</button>
                        <button className="secondary" onClick={() => setRespondingId(null)}>Cancel</button>
                      </div>
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
