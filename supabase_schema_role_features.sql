-- Zulu Inventory: role-based features schema helpers
-- Run in Supabase SQL editor.

-- 1) Customer orders: fields needed for assignments & performance
alter table if exists public.customer_orders
  add column if not exists tailor_id uuid null;

alter table if exists public.customer_orders
  add column if not exists manager_id uuid null;

alter table if exists public.customer_orders
  add column if not exists seller_id uuid null;

alter table if exists public.customer_orders
  add column if not exists completed_at timestamp without time zone null;

-- Optional: add foreign keys (pick ONE target that matches your ids)
-- If tailor_id/seller_id reference public.users.id:
-- alter table public.customer_orders
--   add constraint customer_orders_tailor_id_fkey foreign key (tailor_id) references public.users(id) on delete set null;
-- alter table public.customer_orders
--   add constraint customer_orders_manager_id_fkey foreign key (manager_id) references public.users(id) on delete set null;
-- alter table public.customer_orders
--   add constraint customer_orders_seller_id_fkey foreign key (seller_id) references public.users(id) on delete set null;

-- If tailor_id/seller_id reference auth.users.id:
-- alter table public.customer_orders
--   add constraint customer_orders_tailor_id_fkey foreign key (tailor_id) references auth.users(id) on delete set null;
-- alter table public.customer_orders
--   add constraint customer_orders_manager_id_fkey foreign key (manager_id) references auth.users(id) on delete set null;
-- alter table public.customer_orders
--   add constraint customer_orders_seller_id_fkey foreign key (seller_id) references auth.users(id) on delete set null;


-- 2) Raw material purchase requests
create table if not exists public.raw_material_requests (
  id uuid not null default extensions.uuid_generate_v4(),
  requested_by uuid null,
  material_name text not null,
  unit text null,
  quantity numeric null default 0,
  notes text null,
  status text not null default 'pending',
  created_at timestamp without time zone not null default now(),
  updated_at timestamp without time zone not null default now(),
  constraint raw_material_requests_pkey primary key (id)
);

-- 3) Tailor clock-in/out time logs
create table if not exists public.time_logs (
  id uuid not null default extensions.uuid_generate_v4(),
  user_id uuid not null,
  clock_in timestamp without time zone not null default now(),
  clock_out timestamp without time zone null,
  notes text null,
  created_at timestamp without time zone not null default now(),
  constraint time_logs_pkey primary key (id)
);

-- 4) updated_at trigger helper (optional)
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_raw_material_requests_updated_at on public.raw_material_requests;
create trigger set_raw_material_requests_updated_at
before update on public.raw_material_requests
for each row execute function public.set_updated_at();

-- 5) Minimal RLS (optional; adjust to your security needs)
-- Note: if you enable RLS, you MUST add policies or the app will get 401/403.
-- alter table public.raw_material_requests enable row level security;
-- alter table public.time_logs enable row level security;
-- alter table public.measurements enable row level security;
--
-- Example role-aware policies for raw_material_requests:
-- Assumptions:
-- - `public.users.user_id` stores auth.uid()
-- - `public.users.role` contains 'admin' / 'manager' / etc.
-- - `public.raw_material_requests.requested_by` stores auth.uid()
--
-- Enable RLS:
-- alter table public.raw_material_requests enable row level security;
--
-- Allow authenticated users to read their own requests; admins can read all:
-- drop policy if exists "raw_material_requests_select_own_or_admin" on public.raw_material_requests;
-- create policy "raw_material_requests_select_own_or_admin" on public.raw_material_requests
-- for select to authenticated
-- using (
--   requested_by = auth.uid()
--   or exists (
--     select 1
--     from public.users u
--     where u.user_id = auth.uid()
--       and lower(u.role) = 'admin'
--   )
-- );
--
-- Allow authenticated users to insert requests:
-- drop policy if exists "raw_material_requests_insert_authenticated" on public.raw_material_requests;
-- create policy "raw_material_requests_insert_authenticated" on public.raw_material_requests
-- for insert to authenticated
-- with check (true);
--
-- Only admins can update request status (or any fields):
-- drop policy if exists "raw_material_requests_update_admin_only" on public.raw_material_requests;
-- create policy "raw_material_requests_update_admin_only" on public.raw_material_requests
-- for update to authenticated
-- using (
--   exists (
--     select 1
--     from public.users u
--     where u.user_id = auth.uid()
--       and lower(u.role) = 'admin'
--   )
-- )
-- with check (
--   exists (
--     select 1
--     from public.users u
--     where u.user_id = auth.uid()
--       and lower(u.role) = 'admin'
--   )
-- );
--
-- create policy "time_logs_select_own" on public.time_logs
-- for select to authenticated using (user_id = auth.uid());
-- create policy "time_logs_insert_own" on public.time_logs
-- for insert to authenticated with check (user_id = auth.uid());
-- create policy "time_logs_update_own" on public.time_logs
-- for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

-- Measurements (if RLS enabled):
-- Start permissive, then tighten to tailor/manager rules later.
-- create policy "measurements_select_all" on public.measurements
-- for select to authenticated using (true);
-- create policy "measurements_update_all" on public.measurements
-- for update to authenticated using (true) with check (true);
-- create policy "measurements_insert_all" on public.measurements
-- for insert to authenticated with check (true);

