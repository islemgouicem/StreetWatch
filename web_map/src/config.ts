const sanitizeConfigValue = (value: string) => value.trim().replace(/[^\x20-\x7E]+/g, '');

export const API_BASE_URL = sanitizeConfigValue(
  import.meta.env.VITE_API_BASE_URL || 'https://streetwatch.onrender.com/api/v1',
);

export const SUPABASE_URL = sanitizeConfigValue(import.meta.env.VITE_SUPABASE_URL || '');
export const SUPABASE_ANON_KEY = sanitizeConfigValue(import.meta.env.VITE_SUPABASE_ANON_KEY || '');
