import { useState } from 'react';
import { useFetch } from '../api/useFetch';
import { apiClient, messageFrom } from '../api/client';
import { StatusBadge } from '../components/StatusBadge';

interface AdminInvoice {
  id: string;
  invoiceNumber: string;
  description: string;
  currency: string;
  totalAmount: number;
  status: string;
  issuedAt: string;
  customer: { fullName: string; email: string };
}

export function InvoicesPage() {
  const { data: invoices, loading, error } = useFetch<AdminInvoice[]>('/admin/invoices');
  const [downloadError, setDownloadError] = useState<string | null>(null);
  const [downloadingId, setDownloadingId] = useState<string | null>(null);

  async function downloadPdf(invoice: AdminInvoice) {
    setDownloadError(null);
    setDownloadingId(invoice.id);
    try {
      const response = await apiClient.get(`/admin/invoices/${invoice.id}/pdf`, { responseType: 'blob' });
      const url = window.URL.createObjectURL(new Blob([response.data], { type: 'application/pdf' }));
      const link = document.createElement('a');
      link.href = url;
      link.download = `${invoice.invoiceNumber}.pdf`;
      link.click();
      window.URL.revokeObjectURL(url);
    } catch (e) {
      setDownloadError(messageFrom(e));
    } finally {
      setDownloadingId(null);
    }
  }

  return (
    <div>
      <h2 className="page-title">Invoices</h2>
      {loading && <p className="empty-note">Loading...</p>}
      {error && <p className="error-note">{error}</p>}
      {downloadError && <p className="error-note">{downloadError}</p>}
      {invoices && invoices.length === 0 && <p className="empty-note">No invoices yet.</p>}
      {invoices && invoices.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Invoice #</th>
              <th>Date</th>
              <th>Customer</th>
              <th>Description</th>
              <th>Total</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {invoices.map((inv) => (
              <tr key={inv.id}>
                <td>{inv.invoiceNumber}</td>
                <td>{new Date(inv.issuedAt).toLocaleString()}</td>
                <td>{inv.customer.fullName}</td>
                <td>{inv.description}</td>
                <td>{inv.currency} {inv.totalAmount.toFixed(2)}</td>
                <td><StatusBadge status={inv.status} /></td>
                <td>
                  <button className="secondary" onClick={() => downloadPdf(inv)} disabled={downloadingId === inv.id}>
                    {downloadingId === inv.id ? 'Downloading...' : 'Download PDF'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
