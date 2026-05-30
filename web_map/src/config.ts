const sanitizeConfigValue = (value: string) => value.trim().replace(/[^\x20-\x7E]+/g, '');

const getSupabaseProjectRefFromUrl = (url: string): string | null => {
  try {
    const hostname = new URL(url).hostname;
    const projectRef = hostname.split('.')[0];
    return projectRef || null;
  } catch {
    return null;
  }
};

const getSupabaseProjectRefFromAnonKey = (key: string): string | null => {
  try {
    const payloadPart = key.split('.')[1];
    if (!payloadPart) return null;

    const base64 = payloadPart.replace(/-/g, '+').replace(/_/g, '/');
    const paddedBase64 = base64.padEnd(Math.ceil(base64.length / 4) * 4, '=');
    const payload = JSON.parse(atob(paddedBase64));
    return typeof payload.ref === 'string' ? payload.ref : null;
  } catch {
    return null;
  }
};

export const API_BASE_URL = sanitizeConfigValue(
  import.meta.env.VITE_API_BASE_URL || 'https://streetwatch.onrender.com/api/v1',
);

export const SUPABASE_URL = sanitizeConfigValue(import.meta.env.VITE_SUPABASE_URL || '');
export const SUPABASE_ANON_KEY = sanitizeConfigValue(import.meta.env.VITE_SUPABASE_ANON_KEY || '');

export const SUPABASE_PROJECT_REF = getSupabaseProjectRefFromUrl(SUPABASE_URL);
export const SUPABASE_KEY_REF = getSupabaseProjectRefFromAnonKey(SUPABASE_ANON_KEY);

export const SUPABASE_CONFIG_ERROR =
  SUPABASE_URL && SUPABASE_ANON_KEY && SUPABASE_PROJECT_REF && SUPABASE_KEY_REF &&
  SUPABASE_PROJECT_REF !== SUPABASE_KEY_REF
    ? `Supabase key belongs to project ${SUPABASE_KEY_REF}, but VITE_SUPABASE_URL points to ${SUPABASE_PROJECT_REF}.`
    : null;
