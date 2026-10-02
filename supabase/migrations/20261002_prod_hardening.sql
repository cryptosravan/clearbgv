alter table public.profiles
  add column if not exists last_assessed_at timestamptz,
  add column if not exists assessment_status text not null default 'not_assessed';

create table if not exists public.privacy_consents (
  user_id uuid primary key references auth.users(id) on delete cascade,
  version text not null,
  purposes jsonb not null default '{}'::jsonb,
  consented_at timestamptz not null default now()
);

create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  action text not null,
  entity text,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.privacy_consents enable row level security;
alter table public.audit_events enable row level security;

drop policy if exists "users manage own privacy consent" on public.privacy_consents;
create policy "users manage own privacy consent"
on public.privacy_consents for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "users read own audit events" on public.audit_events;
create policy "users read own audit events"
on public.audit_events for select
using (auth.uid() = user_id);

drop policy if exists "users insert own audit events" on public.audit_events;
create policy "users insert own audit events"
on public.audit_events for insert
with check (auth.uid() = user_id);

create or replace function public.run_readiness_assessment()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  v_score integer := 100;
  emp record;
  prev record;
  has_prev boolean := false;
  gap_days integer;
  result jsonb;
begin
  if uid is null then raise exception 'Authentication required'; end if;

  delete from public.issues where user_id = uid and resolved = false;

  for emp in
    select id, company, role, doj, dor
    from public.employment
    where user_id = uid
    order by doj nulls last, created_at
  loop
    if has_prev and prev.dor is not null and emp.doj is not null then
      gap_days := (emp.doj - prev.dor);
      if gap_days > 30 then
        insert into public.issues(user_id,severity,title,description,deduction,screen)
        values(uid,'medium','Employment gap over 30 days',gap_days || ' day gap between ' ||
          coalesce(prev.company,'previous employer') || ' and ' || coalesce(emp.company,'next employer'),8,'s-employment');
      elsif emp.doj < prev.dor then
        insert into public.issues(user_id,severity,title,description,deduction,screen)
        values(uid,'high','Employment date overlap',coalesce(emp.company,'Current role') || ' overlaps ' ||
          coalesce(prev.company,'previous employer'),15,'s-employment');
      end if;
    end if;

    if emp.dor is not null then
      if not exists (select 1 from public.documents d where d.user_id=uid and lower(coalesce(d.employer,''))=lower(coalesce(emp.company,'')) and d.type='relieving') then
        insert into public.issues(user_id,severity,title,description,deduction,screen)
        values(uid,'high','Relieving letter missing','No relieving letter is linked to ' || coalesce(emp.company,'this previous employer'),15,'s-documents');
      end if;
      if (select count(*) from public.documents d where d.user_id=uid and lower(coalesce(d.employer,''))=lower(coalesce(emp.company,'')) and d.type='payslip') < 3 then
        insert into public.issues(user_id,severity,title,description,deduction,screen)
        values(uid,'medium','Latest 3 payslips missing',coalesce(emp.company,'This employer') ||
          ': fewer than 3 payslips are linked',8,'s-documents');
      end if;
    end if;

    prev := emp;
    has_prev := true;
  end loop;

  if exists(select 1 from public.education where user_id=uid)
     and not exists(select 1 from public.documents where user_id=uid and type='degree') then
    insert into public.issues(user_id,severity,title,description,deduction,screen)
    values(uid,'medium','Degree certificate missing','Upload your degree certificate',8,'s-documents');
  end if;

  if not exists(select 1 from public.addresses where user_id=uid) then
    insert into public.issues(user_id,severity,title,description,deduction,screen)
    values(uid,'low','Address details missing','Add current or permanent address information',3,'s-address');
  end if;

  if not exists(
    select 1 from public.profiles
    where id=uid and nullif(trim(coalesce(profile_data->>'emergency_name','')),'') is not null
  ) then
    insert into public.issues(user_id,severity,title,description,deduction,screen)
    values(uid,'low','Emergency contact missing','Add an emergency contact to complete your profile',3,'s-contact');
  end if;

  v_score := greatest(0,100-coalesce((select sum(i.deduction) from public.issues i where i.user_id=uid and not i.resolved),0));

  update public.profiles p
  set score=v_score,
      readiness_score=v_score,
      readiness_band=case when v_score<=50 then 'Critical' when v_score<=70 then 'Needs Work' when v_score<=89 then 'Good' else 'Ready' end,
      assessment_status='assessed',
      last_assessed_at=now(),
      updated_at=now()
  where p.id=uid;

  select jsonb_build_object(
    'score',v_score,
    'band',(select p.readiness_band from public.profiles p where p.id=uid),
    'issues',coalesce(jsonb_agg(jsonb_build_object(
      'severity',i.severity,'title',i.title,'description',i.description,'deduction',i.deduction,'screen',i.screen
    ) order by case i.severity when 'high' then 1 when 'medium' then 2 else 3 end, i.created_at),'[]'::jsonb)
  )
  into result
  from public.issues i
  where i.user_id=uid and not i.resolved;

  return coalesce(result,jsonb_build_object('score',v_score,'band','Ready','issues','[]'::jsonb));
end;
$$;

grant execute on function public.run_readiness_assessment() to authenticated;