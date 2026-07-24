import { createContext, useContext, useMemo, useState, type ReactNode } from 'react';
import { apiClient, getStoredToken, messageFrom, setStoredToken } from '../api/client';

interface AuthContextValue {
  isAuthenticated: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<boolean>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [isAuthenticated, setIsAuthenticated] = useState(() => Boolean(getStoredToken()));
  const [error, setError] = useState<string | null>(null);

  const login = async (email: string, password: string) => {
    setError(null);
    try {
      const response = await apiClient.post('/auth/login', { email, password });
      setStoredToken(response.data.accessToken);
      setIsAuthenticated(true);
      return true;
    } catch (e) {
      setError(messageFrom(e));
      return false;
    }
  };

  const logout = () => {
    setStoredToken(null);
    setIsAuthenticated(false);
  };

  const value = useMemo(() => ({ isAuthenticated, error, login, logout }), [isAuthenticated, error]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
