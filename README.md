# ClearBGV

ClearBGV is a candidate-facing BGV readiness product for Indian IT professionals. It helps a user organize employment, education, identity/address and document evidence before an employer background-verification process.

## Repository layout

- `index.html` — deployable static web app
- `supabase-config.js` — browser-safe Supabase project URL + publishable key
- `supabase-schema.sql` — database/storage schema with RLS policies
- `README_DEPLOY.md` — deployment and production-hardening notes
- `.env.example` — placeholder guidance for a future Vite/Next.js migration

## Current stack

Static HTML/CSS/JavaScript + Supabase Auth, Postgres, Storage and Row Level Security.

## ClearBGV flow

Signup → Basic Profile → Employment History → Education → Identity & Address → Upload Documents → Run BGV Check → Review Issues → Fix Issues → Re-run → Generate Report → Share Report → Reminders / Offer Letter Review.

## Important security note

Only the Supabase publishable/anon key belongs in browser code. Never commit a Supabase service_role/secret key.

The current app is a pre-BGV readiness/self-assessment tool. It is not an employer BGV result or a guarantee of employment verification outcome.

Before accepting real Aadhaar, PAN, payslip or offer-letter documents from paying users, complete a production privacy/security review, configure retention/deletion policies, SMTP, rate limiting, monitoring and any DPDPA requirements applicable to the final service.

## Cloudflare Pages

Recommended deployment target: Cloudflare Pages. This repo is a static site and does not need a build command; the production output is the repository root.

## Known product limitations

Offer-letter files are stored, but automated clause extraction is not yet implemented. Reminder records are persisted, but actual email/SMS delivery needs a server-side delivery provider. The readiness score is currently calculated in the browser and should be moved to a trusted server-side implementation before treating it as authoritative.
