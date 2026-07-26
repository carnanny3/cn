import { useState } from 'react';
import { apiClient, messageFrom } from '../api/client';
import { useFetch } from '../api/useFetch';

interface CmsContent {
  id: string;
  section: string;
  locale: string;
  title: string;
  body: string;
  order: number;
}

export function CmsPage() {
  const [refreshKey, setRefreshKey] = useState(0);
  const [actionError, setActionError] = useState<string | null>(null);
  const [section, setSection] = useState('faq');
  const [locale, setLocale] = useState('en');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [editingId, setEditingId] = useState<string | null>(null);
  const { data, loading, error } = useFetch<CmsContent[]>('/cms', [refreshKey]);

  const resetForm = () => {
    setEditingId(null);
    setTitle('');
    setBody('');
  };

  const startEdit = (c: CmsContent) => {
    setEditingId(c.id);
    setSection(c.section);
    setLocale(c.locale);
    setTitle(c.title);
    setBody(c.body);
  };

  const submit = async () => {
    setActionError(null);
    try {
      if (editingId) {
        await apiClient.patch(`/cms/${editingId}`, { title, body });
      } else {
        await apiClient.post('/cms', { section, locale, title, body });
      }
      resetForm();
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  const remove = async (id: string) => {
    setActionError(null);
    try {
      await apiClient.delete(`/cms/${id}`);
      setRefreshKey((k) => k + 1);
    } catch (e) {
      setActionError(messageFrom(e));
    }
  };

  return (
    <div>
      <h2 className="page-title">CMS &amp; FAQs</h2>
      {actionError && <p className="error-note">{actionError}</p>}

      <div className="form-card">
        <div className="field-row">
          <label>Section (e.g. faq, legal_terms, legal_privacy)</label>
          <input value={section} onChange={(e) => setSection(e.target.value)} disabled={!!editingId} />
        </div>
        <div className="field-row">
          <label>Locale</label>
          <select value={locale} onChange={(e) => setLocale(e.target.value)} disabled={!!editingId}>
            <option value="en">English</option>
            <option value="ar">Arabic</option>
          </select>
        </div>
        <div className="field-row">
          <label>Title</label>
          <input value={title} onChange={(e) => setTitle(e.target.value)} />
        </div>
        <div className="field-row">
          <label>Body</label>
          <textarea rows={4} value={body} onChange={(e) => setBody(e.target.value)} />
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={submit}>{editingId ? 'Save changes' : 'Create'}</button>
          {editingId && <button className="secondary" onClick={resetForm}>Cancel</button>}
        </div>
      </div>

      {loading && <p className="empty-note">Loading...</p>}
      {error && <p className="error-note">{error}</p>}
      {data && data.length === 0 && <p className="empty-note">No content yet.</p>}
      {data && data.length > 0 && (
        <table>
          <thead>
            <tr>
              <th>Section</th>
              <th>Locale</th>
              <th>Title</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {data.map((c) => (
              <tr key={c.id}>
                <td>{c.section}</td>
                <td>{c.locale}</td>
                <td>{c.title}</td>
                <td>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <button className="secondary" onClick={() => startEdit(c)}>Edit</button>
                    <button className="secondary" onClick={() => remove(c.id)}>Delete</button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
