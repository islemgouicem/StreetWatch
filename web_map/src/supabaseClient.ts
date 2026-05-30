import { createClient } from '@supabase/supabase-js';

// Matches the Flutter app's Supabase project
const SUPABASE_URL = 'https://kcqnmcvzngikknstnfle.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtjcW5tY3Z6bmdpa2tuc3RuZmxlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MTQ0OTgsImV4cCI6MjA5MTQ5MDQ5OH0.UWfh-nPvfyiGPD9aqUvd2DMM0f-K97LrR3JGHLeyqxk';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
