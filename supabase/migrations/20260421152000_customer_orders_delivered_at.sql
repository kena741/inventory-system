alter table public.customer_orders
  add column if not exists delivered_at timestamp without time zone null;

