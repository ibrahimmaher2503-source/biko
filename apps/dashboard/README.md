# Biko Unified Dashboard

One Next.js application for platform and office users. Authentication uses
Supabase Email + Password with cookie-backed SSR sessions; the dashboard shell
reads the bounded `get_dashboard_context()` RPC and only exposes navigation
items available to the current role or office membership.

```powershell
npm install
npm run dev
npm run lint
npm run build
```

Copy `.env.example` to `.env.local` only after a Development Supabase project
exists. Never place a service-role key in this browser application.
