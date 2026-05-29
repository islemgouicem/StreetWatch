import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react';
import type { Session, User } from '@supabase/supabase-js';
import { API_BASE_URL } from '../config';
import { isSupabaseConfigured, supabase } from '../supabaseClient';

type AuthUser = User & { is_admin?: boolean };

interface AuthContextValue {
  session: Session | null;
  user: AuthUser | null;
  isAdmin: boolean;
  isLoading: boolean;
  signIn: (email: string, password: string) => Promise<string | null>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  const loadAdminFlag = async (token: string) => {
    try {
      const res = await fetch(`${API_BASE_URL}/auth/me`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        setIsAdmin(Boolean(data.is_admin));
      }
    } catch {
      setIsAdmin(false);
    }
  };

  useEffect(() => {
    if (!supabase) {
      setIsLoading(false);
      return;
    }

    supabase.auth.getSession().then(({ data: { session: s } }) => {
      setSession(s);
      setUser((s?.user as AuthUser) ?? null);
      if (s?.access_token) {
        loadAdminFlag(s.access_token).finally(() => setIsLoading(false));
      } else {
        setIsLoading(false);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, s) => {
      setSession(s);
      setUser((s?.user as AuthUser) ?? null);
      if (s?.access_token) {
        loadAdminFlag(s.access_token);
      } else {
        setIsAdmin(false);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const signIn = async (email: string, password: string): Promise<string | null> => {
    if (!supabase) {
      return 'Missing Supabase frontend configuration. Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY, then rebuild the web image.';
    }

    const { error } = await supabase.auth.signInWithPassword({ email, password });
    return error ? error.message : null;
  };

  const signOut = async () => {
    await supabase?.auth.signOut();
  };

  if (!isSupabaseConfigured) {
    return (
      <div className="splash-loader">
        <div style={{ maxWidth: 620, padding: '2rem', textAlign: 'left' }}>
          <p className="section-label">Configuration Required</p>
          <h2>Missing Supabase frontend env vars</h2>
          <p>
            Set <code>VITE_SUPABASE_URL</code> and <code>VITE_SUPABASE_ANON_KEY</code> in the
            root <code>.env</code> file, then rebuild with <code>docker compose up -d --build</code>.
          </p>
        </div>
      </div>
    );
  }

  return (
    <AuthContext.Provider value={{ session, user, isAdmin, isLoading, signIn, signOut }}>
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used inside AuthProvider');
  return ctx;
}
