-- Clock-in / clock-out for staff (matches Flutter: ErpRepository clockIn / clockOut / listMyTimeLogs).
-- user_id must equal auth.users.id (Supabase session uid).

create table if not exists public.time_logs (
  id uuid not null default gen_random_uuid (),
  user_id uuid not null,
  clock_in timestamptz not null default now(),
  clock_out timestamptz null,
  notes text null,
  created_at timestamptz not null default now(),
  constraint time_logs_pkey primary key (id),
  constraint time_logs_clock_order check (
    clock_out is null
    or clock_out >= clock_in
  )
);

comment on table public.time_logs is 'Check-in (clock_in) and check-out (clock_out) per user; open session has clock_out null.';

create index if not exists time_logs_user_clock_in_desc on public.time_logs (user_id, clock_in desc);

create index if not exists time_logs_open_session on public.time_logs (user_id)
where
  clock_out is null;

-- Optional: enforce at most one open session per user (uncomment if you have no duplicate open rows yet).
-- create unique index if not exists time_logs_one_open_per_user
--   on public.time_logs (user_id)
--   where (clock_out is null);

alter table public.time_logs enable row level security;

-- Replace policies if you re-run this migration in SQL editor (safe for idempotent deploys).
drop policy if exists "time_logs_select_own" on public.time_logs;

drop policy if exists "time_logs_insert_own" on public.time_logs;

drop policy if exists "time_logs_update_own" on public.time_logs;

create policy "time_logs_select_own" on public.time_logs for
select
  to authenticated using (user_id = auth.uid());

create policy "time_logs_insert_own" on public.time_logs for insert to authenticated
with
  check (user_id = auth.uid());

-- Checkout sets clock_out on the caller own row.
create policy "time_logs_update_own" on public.time_logs for
update to authenticated using (user_id = auth.uid())
with
  check (user_id = auth.uid());

-- Optional: managers/admins see all rows (uncomment and adjust public.users to match your schema).
-- create policy "time_logs_select_admin" on public.time_logs for select to authenticated using (
--   exists (
--     select 1
--     from public.users u
--     where u.user_id = auth.uid()
--       and lower(coalesce(u.role, '')) in ('admin', 'manager')
--   )
-- );
