import { useState } from 'react';
import { useAuth } from '../state/AuthContext';

export function LoginPage() {
  const { login, error } = useAuth();
  const [email, setEmail] = useState('admin@carnanny.app');
  const [password, setPassword] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const submit = async () => {
    setSubmitting(true);
    await login(email, password);
    setSubmitting(false);
  };

  return (
    <div className="login-screen">
      <div className="login-card">
        <h1>Car Nanny Admin</h1>
        <label>Email</label>
        <input value={email} onChange={(e) => setEmail(e.target.value)} type="email" />
        <label>Password</label>
        <input
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          type="password"
          onKeyDown={(e) => e.key === 'Enter' && submit()}
        />
        <button onClick={submit} disabled={submitting}>
          {submitting ? 'Signing in...' : 'Sign in'}
        </button>
        {error && <div className="error-note">{error}</div>}
      </div>
    </div>
  );
}
