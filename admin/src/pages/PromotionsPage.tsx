import { useState } from 'react';
import { apiClient, messageFrom } from '../api/client';
import { useFetch } from '../api/useFetch';
import { StatusBadge } from '../components/StatusBadge';

interface Coupon {
  id: string;
  code: string;
  description: string | null;
  discountType: 'percentage' | 'fixed_amount';
  discountValue: number;
  maxRedemptions: number | null;
  redeemedCount: number;
  expiresAt: string | null;
  active: boolean;
}

export function PromotionsPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [actionError, setActionError] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [description, setDescription] = useState('');
  const [discountType, setDiscountType] = useState<'percentage' | 'fixed_amount'>('percentage');
  const [discountValue, setDiscountValue] = useState('');
  const [maxRedemptions, setMaxRedemptions] = useState('');
  const [expiresAt, setExpiresAt] = useState('');
  const { data, loading, error } = useFetch<Coupon[]>('/promotions', [refreshKey]);

  const submit = async () => {
    setActionError(null);
    try {
      await apiClient.post('/promotions', {
        code,
        description: description || undefined,
        discountType,
        discountValue: Number(discountValue),
        maxRedemptions: maxRedemptions ? Number(maxRedemptions) : undefined,
        expiresAt: expiresAt ? new Date(expiresAt).toISOString() : undefined,
      });
      setCode('');
      setDescription('');
      setDiscountValue('');
      setMaxRedemptions('');
      setExpiresAt('');
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  const toggleActive = async (id: string, active: boolean) => {
    setActionError(null);
    try {
      await apiClient.patch(`/promotions/${id}`, { active: !active });
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  return (
    <div>
      <h2 className="page-title">Promotions &amp; Coupons</h2>
      {actionError && <p className="error-note">{actionError}</p>}

      <div className="form-card">
        <div className="field-row">
          <label>Code</label>
          <input value={code} onChange={(e) => setCode(e.target.value.toUpperCase())} placeholder="WELCOME10" />
        </div>
        <div className="field-row">
          <label>Description</label>
          <input value={description} onChange={(e) => setDescription(e.target.value)} />
        </div>
        <div className="field-row">
          <label>Discount type</label>
          <select value={discountType} onChange={(e) => setDiscountType(e.target.value as 'percentage' | 'fixed_amount')}>
            <option value="percentage">Percentage</option>
            <option value="fixed_amount">Fixed amount (AED)</option>
          </select>
        </div>
        <div className="field-row">
          <label>Discount value</label>
          <input value={discountValue} onChange={(e) => setDiscountValue(e.target.value)} />
        </div>
        <div className="field-row">
          <label>Max redemptions (optional)</label>
          <input value={maxRedemptions} onChange={(e) => setMaxRedemptions(e.target.value)} />
        </div>
        <div className="field-row">
          <label>Expires at (optional)</label>
          <input type="date" value={expiresAt} onChange={(e) => setExpiresAt(e.target.value)} />
        </div>
        <button onClick={submit}>Create coupon</button>
      </div>

      {loading && <p className="empty-note">Loading...</p>}
      {error && <p className="error-note">{error}</p>}
      {data && data.length === 0 && <p className="empty-note">No coupons yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Code</th>
              <th>Discount</th>
              <th>Redeemed</th>
              <th>Expires</th>
              <th>Status</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {data.map((c) => (
              <tr key={c.id}>
                <td>{c.code}</td>
                <td>{c.discountType === 'percentage' ? `${c.discountValue}%` : `AED ${c.discountValue}`}</td>
                <td>{c.redeemedCount}{c.maxRedemptions ? ` / ${c.maxRedemptions}` : ''}</td>
                <td>{c.expiresAt ? new Date(c.expiresAt).toLocaleDateString() : '—'}</td>
                <td><StatusBadge status={c.active ? 'active' : 'suspended'} /></td>
                <td>
                  <button className="secondary" onClick={() => toggleActive(c.id, c.active)}>
                    {c.active ? 'Deactivate' : 'Activate'}
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
