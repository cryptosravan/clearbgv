-- ClearBGV Supabase schema
-- Recreates the current production database objects used by the static app.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  profile_data jsonb not null default '{}'::jsonb,
  settings jsonb not null default '{}'::jsonb,
  readiness_score integer,
  readiness_band text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.employment (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  company text not null,
  role text,
  doj date,
  dor date,
  emp_id text,
  verified boolean not null default false,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.education (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  degree text not null,
  institution text,
  year text,
  score text,
  verified boolean not null default false,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  address_type text,
  line1 text,
  line2 text,
  city text,
  state text,
  pincode text,
  from_date date,
  to_date date,
  address text,
  verified boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null,
  employer text,
  file_path text,
  status text not null default 'uploaded',
  metadata jsonb not null default '{}'::jsonb,
  uploaded_on timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.issues (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  severity text not null,
  title text not null,
  description text,
  deduction integer not null default 0,
  screen text,
  resolved boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reminders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  due timestamptz,
  channel text not null default 'email',
  done boolean not null default false,
  type text,
  priority text not null default 'medium',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  score integer,
  report_data jsonb not null default '{}'::jsonb,
  share_token text unique,
  share_expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.offer_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  file_path text,
  file_name text,
  review_data jsonb not null default '{}'::jsonb,
  status text not null default 'uploaded',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  subject text,
  message text not null,
  category text,
  priority text not null default 'normal',
  status text not null default 'open',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at before update on public.profiles for each row execute function public.set_updated_at();

drop trigger if exists employment_updated_at on public.employment;
create trigger employment_updated_at before update on public.employment for each row execute function public.set_updated_at();

drop trigger if exists education_updated_at on public.education;
create trigger education_updated_at before update on public.education for each row execute function public.set_updated_at();

drop trigger if exists addresses_updated_at on public.addresses;
create trigger addresses_updated_at before update on public.addresses for each row execute function public.set_updated_at();

drop trigger if exists documents_updated_at on public.documents;
create trigger documents_updated_at before update on public.documents for each row execute function public.set_updated_at();

drop trigger if exists issues_updated_at on public.issues;
create trigger issues_updated_at before update on public.issues for each row execute function public.set_updated_at();

drop trigger if exists reminders_updated_at on public.reminders;
create trigger reminders_updated_at before update on public.reminders for each row execute function public.set_updated_at();

drop trigger if exists offer_reviews_updated_at on public.offer_reviews;
create trigger offer_reviews_updated_at before update on public.offer_reviews for each row execute function public.set_updated_at();

drop trigger if exists support_tickets_updated_at on public.support_tickets;
create trigger support_tickets_updated_at before update on public.support_tickets for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.employment enable row level security;
alter table public.education enable row level security;
alter table public.addresses enable row level security;
alter table public.documents enable row level security;
alter table public.issues enable row level security;
alter table public.reminders enable row level security;
alter table public.reports enable row level security;
alter table public.offer_reviews enable row level security;
alter table public.support_tickets enable row level security;

drop policy if exists "profiles own" on public.profiles;
create policy "profiles own" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "employment own" on public.employment;
create policy "employment own" on public.employment for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "education own" on public.education;
create policy "education own" on public.education for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "addresses own" on public.addresses;
create policy "addresses own" on public.addresses for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "documents own" on public.documents;
create policy "documents own" on public.documents for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "issues own" on public.issues;
create policy "issues own" on public.issues for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "reminders own" on public.reminders;
create policy "reminders own" on public.reminders for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "reports own" on public.reports;
create policy "reports own" on public.reports for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "shared reports public read" on public.reports;
create policy "shared reports public read" on public.reports for select to anon using (share_token is not null and share_expires_at > now());

drop policy if exists "offer_reviews own" on public.offer_reviews;
create policy "offer_reviews own" on public.offer_reviews for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "support_tickets own" on public.support_tickets;
create policy "support_tickets own" on public.support_tickets for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create index if not exists employment_user_id_idx on public.employment(user_id);
create index if not exists education_user_id_idx on public.education(user_id);
create index if not exists addresses_user_id_idx on public.addresses(user_id);
create index if not exists documents_user_id_idx on public.documents(user_id);
create index if not exists issues_user_id_idx on public.issues(user_id);
create index if not exists reminders_user_id_idx on public.reminders(user_id);
create index if not exists reports_user_id_idx on public.reports(user_id);
create index if not exists offer_reviews_user_id_idx on public.offer_reviews(user_id);
create index if not exists support_tickets_user_id_idx on public.support_tickets(user_id);

insert into storage.buckets (id, name, public)
values ('clearbgv-documents', 'clearbgv-documents', false)
on conflict (id) do update set public = excluded.public;

drop policy if exists "documents storage own select" on storage.objects;
create policy "documents storage own select" on storage.objects for select to authenticated
using (bucket_id = 'clearbgv-documents' and (storage.foldername(name))[1] = (auth.uid())::text);

drop policy if exists "documents storage own insert" on storage.objects;
create policy "documents storage own insert" on storage.objects for insert to authenticated
with check (bucket_id = 'clearbgv-documents' and (storage.foldername(name))[1] = (auth.uid())::text);

drop policy if exists "documents storage own update" on storage.objects;
create policy "documents storage own update" on storage.objects for update to authenticated
using (bucket_id = 'clearbgv-documents' and (storage.foldername(name))[1] = (auth.uid())::text)
with check (bucket_id = 'clearbgv-documents' and (storage.foldername(name))[1] = (auth.uid())::text);

drop policy if exists "documents storage own delete" on storage.objects;
create policy "documents storage own delete" on storage.objects for delete to authenticated
using (bucket_id = 'clearbgv-documents' and (storage.foldername(name))[1] = (auth.uid())::text);

-- App payload compatibility columns are included above (employment/education data,
-- address verification, reminder type/priority, document uploaded_on, support metadata).
