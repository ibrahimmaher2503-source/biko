# Manual Setup

## Hosted Supabase Development project

Status: **NOT CONNECTED**. The repository has local Supabase configuration only; no hosted project reference or real hosted credentials are configured.

Manual action required:

1. Create or select a separate hosted Supabase Development project.
2. Link this repository to that Development project with the Supabase CLI.
3. Put its URL, publishable key, project reference, access token, and database password only in ignored local environment files; keep every `.env.example` placeholder-only.
4. Do not put the service-role key in either Flutter app or the dashboard.

## Supabase

1. Create separate Development and Production Supabase projects.
2. Keep email/password authentication enabled for the current scope; SMS/OTP remains disabled by DEC-001.
3. Copy `apps/*/.env.example` and `apps/dashboard/.env.example` values into local, uncommitted environment configuration.
4. Apply migrations with the Supabase CLI after linking the intended project.
5. Never expose the service-role key in Flutter or browser builds.

Local development can use `npx supabase start` and `npx supabase db reset` when Docker Desktop is running.

## Later credentials

Firebase/FCM and restricted Google Maps credentials are intentionally deferred until the core order and bidding flow works. Their placeholders exist in `.env.example` only.

## Missing authority documents

The controller references these files, but they were not present in the supplied workspace:

- `Master_Technical_Specification_EN.md`
- `Motorcycle_Platform_Project_Requirements_EN.md`
- UI/UX design documents

Add them under `docs/` before requirements that depend on their missing details are finalized.
