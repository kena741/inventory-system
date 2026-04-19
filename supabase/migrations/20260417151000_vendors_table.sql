-- Vendors master list (admin-managed; no vendor login).

create table if not exists public.vendors (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  address text,
  created_at timestamptz not null default now()
);

create index if not exists vendors_name_idx on public.vendors (name);

alter table public.vendors enable row level security;

-- Admin-only CRUD (assumes public.users.user_id = auth.uid() and public.users.role contains 'admin').
drop policy if exists "vendors_admin_all" on public.vendors;
create policy "vendors_admin_all" on public.vendors
for all
to authenticated
using (
  exists (
    select 1
    from public.users u
    where u.user_id = auth.uid()
      and lower(coalesce(u.role, '')) = 'admin'
  )
)
with check (
  exists (
    select 1
    from public.users u
    where u.user_id = auth.uid()
      and lower(coalesce(u.role, '')) = 'admin'
  )
);

