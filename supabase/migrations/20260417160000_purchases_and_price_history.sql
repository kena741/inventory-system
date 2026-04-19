-- Recorded when a manager completes a raw material request (receipt).
-- See also: public.vendors, public.raw_materials, public.raw_material_requests

-- Optional: allow managers to list vendors (for receipt UI) while admin keeps full access.
drop policy if exists "vendors_read_manager" on public.vendors;
create policy "vendors_read_manager" on public.vendors
for select
  to authenticated
  using (
    exists (
      select 1
      from public.users u
      where u.user_id = auth.uid()
        and lower(coalesce(u.role, '')) = 'manager'
    )
  );

create table if not exists public.purchases (
  id uuid primary key default gen_random_uuid(),
  raw_material_request_id uuid null
    references public.raw_material_requests (id) on delete set null,
  vendor_id uuid null
    references public.vendors (id) on delete set null,
  branch_id uuid null,
  purchase_date date not null default (current_date),
  payment_type text not null default 'cash'
    check (payment_type in ('cash', 'credit')),
  remark text null,
  total_amount numeric(12, 2) null,
  created_at timestamptz not null default now()
);

comment on column public.purchases.vendor_id is 'Optional aggregate vendor (e.g. primary); line-level vendors live on purchase_lines.';

create index if not exists purchases_request_idx on public.purchases (raw_material_request_id);

create table if not exists public.purchase_lines (
  id uuid primary key default gen_random_uuid(),
  purchase_id uuid not null references public.purchases (id) on delete cascade,
  vendor_id uuid null references public.vendors (id) on delete set null,
  raw_material_id uuid null references public.raw_materials (id) on delete set null,
  meters numeric(14, 4) null,
  qty_good numeric(14, 4) null default 0,
  qty_damaged numeric(14, 4) null default 0,
  unit_price numeric(12, 2) null,
  line_total numeric(12, 2) null,
  created_at timestamptz not null default now()
);

create index if not exists purchase_lines_purchase_idx on public.purchase_lines (purchase_id);

create table if not exists public.price_history (
  id uuid not null default gen_random_uuid(),
  raw_material_id uuid null references public.raw_materials (id) on delete cascade,
  price numeric(10, 2) not null,
  start_date date not null default (current_date),
  end_date date null,
  created_at timestamptz null default now(),
  constraint price_history_pkey primary key (id)
);

create index if not exists price_history_material_idx on public.price_history (raw_material_id);

alter table public.purchases enable row level security;

alter table public.purchase_lines enable row level security;

alter table public.price_history enable row level security;

drop policy if exists "purchases_manager_admin_all" on public.purchases;
create policy "purchases_manager_admin_all" on public.purchases for all to authenticated using (
  exists (
    select 1
    from public.users u
    where u.user_id = auth.uid ()
      and lower(coalesce(u.role, '')) in ('admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.users u
    where u.user_id = auth.uid ()
      and lower(coalesce(u.role, '')) in ('admin', 'manager')
  )
);

drop policy if exists "purchase_lines_manager_admin_all" on public.purchase_lines;
create policy "purchase_lines_manager_admin_all" on public.purchase_lines for all to authenticated using (
  exists (
    select 1
    from public.users u
    where u.user_id = auth.uid ()
      and lower(coalesce(u.role, '')) in ('admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.users u
    where u.user_id = auth.uid ()
      and lower(coalesce(u.role, '')) in ('admin', 'manager')
  )
);

drop policy if exists "price_history_manager_admin_all" on public.price_history;
create policy "price_history_manager_admin_all" on public.price_history for all to authenticated using (
  exists (
    select 1
    from public.users u
    where u.user_id = auth.uid ()
      and lower(coalesce(u.role, '')) in ('admin', 'manager')
  )
)
with check (
  exists (
    select 1
    from public.users u
    where u.user_id = auth.uid ()
      and lower(coalesce(u.role, '')) in ('admin', 'manager')
  )
);
