create table if not exists public.order_quality_checks (
  id uuid not null default gen_random_uuid(),
  order_id uuid not null,
  checker_id uuid null,
  tailor_id uuid null,
  status text not null default 'pending'
    check (status in ('pending', 'passed', 'rework', 'failed')),
  materials_used jsonb null,
  embroidery_level int null check (embroidery_level between 0 and 5),
  decoration_level int null check (decoration_level between 0 and 5),
  geber_level int null check (geber_level between 0 and 5),
  notes text null,
  created_at timestamp without time zone not null default now(),
  updated_at timestamp without time zone not null default now(),
  constraint order_quality_checks_pkey primary key (id),
  constraint order_quality_checks_order_id_key unique (order_id),
  constraint order_quality_checks_order_id_fkey
    foreign key (order_id) references public.customer_orders(id) on delete cascade
);

create index if not exists order_quality_checks_order_id_idx
  on public.order_quality_checks(order_id);

create index if not exists order_quality_checks_status_idx
  on public.order_quality_checks(status);

