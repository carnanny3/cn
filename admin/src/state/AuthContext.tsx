import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';
import { apiClient, getStoredToken, messageFrom, setStoredToken } from '../api/client';

interface AuthContextValue {
  isAuthenticated: boolean;
  role: string | null;
  error: string | null;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

// No signature verification needed here — the server already verifies the
// token on every request; this is purely to pick which nav items to show.
function roleFromToken(token: string | null): string | null {
  if (!token) return null;
  try {
    const payload = token.split('.')[1];
    const decoded = JSON.parse(atob(payload.replace(/-/g, '+').replace(/_/g, '/')));
    return decoded.role ?? null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState(() => getStoredToken());
  const [error, setError] = useState<string | null>(null);

  const login = async (email: string, password: string) => {
    setError(null);
    try {
      const response = await apiClient.post('/auth/login', { email, password });
      setStoredToken(response.data.accessToken);
      setToken(response.data.accessToken);
      return true;
    } catch (e) {
      setError(messageFrom(e));
      return false;
    }
  };

  const logout = () => {
    setStoredToken(null);
    setToken(null);
  };

  const value = useMemo(
    () => ({ isAuthenticated: Boolean(token), role: roleFromToken(token), error, login, logout }),
    [token, error],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
