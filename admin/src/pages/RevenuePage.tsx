import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

interface RevenueBucket {
  total: number;
  count: number;
  vat?: number;
}

interface RevenueSummary {
  captured: RevenueBucket;
  refunded: RevenueBucket;
  pending: RevenueBucket;
  failed: RevenueBucket;
  netRevenue: number;
}

interface AdminPayment {
  id: string;
  amount: number;
  currency: string;
  status: string;
  paymentMethod: string;
  relatedEntityType: string;
  createdAt: string;
}

export function RevenuePage() {
  const { data: summary, loading: summaryLoading, error: summaryError } = useFetch<RevenueSummary>('/admin/reports/revenue');
  const { data: payments, loading: paymentsLoading, error: paymentsError } = useFetch<AdminPayment[]>('/admin/payments');

  const cards = summary
    ? [
        { label: 'Net revenue', value: `AED ${summary.netRevenue.toFixed(0)}` },
        { label: 'Captured', value: `AED ${summary.captured.total.toFixed(0)} (${summary.captured.count})` },
        { label: 'Refunded', value: `AED ${summary.refunded.total.toFixed(0)} (${summary.refunded.count})` },
        { label: 'Pending', value: `AED ${summary.pending.total.toFixed(0)} (${summary.pending.count})` },
        { label: 'Failed', value: `AED ${summary.failed.total.toFixed(0)} (${summary.failed.count})` },
      ]
    : [];

  return (
    <div>
      <h2 className="page-title">Payments &amp; Revenue</h2>
      {summaryLoading && <p className="empty-note">Loading summary...</p>}
      {summaryError && <p className="error-note">{summaryError}</p>}
      {summary && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))', gap: 16, marginBottom: 28 }}>
          {cards.map((c) => (
            <div key={c.label} style={{ border: '1px solid var(--border)', borderRadius: 12, padding: 20 }}>
              <div style={{ fontSize: 22, fontWeight: 600 }}>{c.value}</div>
              <div style={{ color: 'var(--text-secondary)', fontSize: 13 }}>{c.label}</div>
            </div>
          ))}
        </div>
      )}

      <h3 style={{ fontSize: 16, marginBottom: 12 }}>Recent Payments</h3>
      {paymentsLoading && <p className="empty-note">Loading...</p>}
      {paymentsError && <p className="error-note">{paymentsError}</p>}
      {payments && payments.length === 0 && <p className="empty-note">No payments yet.</p>}
      {payments && payments.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Related to</th>
              <th>Method</th>
              <th>Amount</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {payments.map((p) => (
              <tr key={p.id}>
                <td>{new Date(p.createdAt).toLocaleString()}</td>
                <td>{p.relatedEntityType.replace(/_/g, ' ')}</td>
                <td>{p.paymentMethod.replace(/_/g, ' ')}</td>
                <td>{p.currency} {p.amount.toFixed(0)}</td>
                <td><StatusBadge status={p.status} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
