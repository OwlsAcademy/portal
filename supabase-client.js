// ── Owl's Academy — Supabase client ──────────────────────────
// Replace the two values below with your project's credentials.
// Find them in: Supabase Dashboard → Project Settings → API
//
//   Project URL  → SUPABASE_URL
//   anon / public → SUPABASE_ANON_KEY
//
// The anon key is safe to expose in frontend code — it is
// intentionally public and limited by Row Level Security policies.

const SUPABASE_URL      = 'https://oilitfktzemvathmefpc.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_3Qq3Cxv80-KbL5ybAywj3Q_-c-CCws0';

const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
