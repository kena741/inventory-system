-- Customer contact number on customer_orders.

alter table public.customer_orders
  add column if not exists customer_number text null;
