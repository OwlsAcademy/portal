// ── Owl's Academy — Supabase client ──────────────────────────
// Replace the two values below with your project's credentials.
// Find them in: Supabase Dashboard → Project Settings → API
//
//   Project URL  → SUPABASE_URL
//   anon / public → SUPABASE_ANON_KEY
//
// The anon key is safe to expose in frontend code — it is
// intentionally public and limited by Row Level Security policies.

const SUPABASE_URL      = 'YOUR_SUPABASE_URL';
const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';

const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
