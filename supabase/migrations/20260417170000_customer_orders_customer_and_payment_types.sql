-- Extra customer fields and payment-channel tracking on customer_orders.

alter table public.customer_orders
  add column if not exists customer_interest text null;

alter table public.customer_orders
  add column if not exists customer_address text null;

alter table public.customer_orders
  add column if not exists initial_payment_payment_type text null;

alter table public.customer_orders
  add column if not exists final_payment_payment_type text null;

alter table public.customer_orders
  drop constraint if exists customer_orders_initial_payment_payment_type_check;

alter table public.customer_orders
  add constraint customer_orders_initial_payment_payment_type_check check (
    initial_payment_payment_type is null
    or lower(initial_payment_payment_type) in ('cash', 'bank')
  );

alter table public.customer_orders
  drop constraint if exists customer_orders_final_payment_payment_type_check;

alter table public.customer_orders
  add constraint customer_orders_final_payment_payment_type_check check (
    final_payment_payment_type is null
    or lower(final_payment_payment_type) in ('cash', 'bank')
  );
