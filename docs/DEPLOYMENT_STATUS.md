# ClearBGV deployment status

## Current deployment

- GitHub: `cryptosravan/clearbgv`
- Production branch: `main`
- Cloudflare Pages project: `clearbgv`
- Canonical Pages domain: `https://clearbgv.pages.dev`
- Latest verified production deployment: `60ac7b80`
- Deployment status: successful

## Deployment architecture

The Cloudflare Pages deployment currently uses a small Pages Worker as the serving layer. The Worker serves the ClearBGV entrypoint from the GitHub `main` branch and serves `supabase-config.js` from the same branch.

This fallback was used because the Cloudflare Pages Git-source connection returned an internal Git installation error. The project is still deployed and the production deployment is successful.

## Supabase

The application is configured against the ClearBGV Supabase project using the browser-safe publishable key. Real user data is protected with Row Level Security and the document bucket is private.

Before public launch with sensitive documents, configure Auth redirect URLs, SMTP, retention/deletion, rate limits, monitoring and privacy/DPDPA requirements for the final service.
