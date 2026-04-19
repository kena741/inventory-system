-- Per-line payment (cash/credit) and remark on purchase_lines; purchase header optional.

alter table public.purchase_lines
  add column if not exists payment_type text;

alter table public.purchase_lines
  add column if not exists remark text;

update public.purchase_lines
set payment_type = 'cash'
where payment_type is null;

alter table public.purchase_lines
  alter column payment_type set default 'cash';

alter table public.purchase_lines
  alter column payment_type set not null;

alter table public.purchase_lines
  drop constraint if exists purchase_lines_payment_type_chk;

alter table public.purchase_lines
  add constraint purchase_lines_payment_type_chk check (payment_type in ('cash', 'credit'));

-- Receipt can mix cash/credit lines; header row no longer carries a single payment type.
alter table public.purchases
  alter column payment_type drop not null;

alter table public.purchases
  alter column payment_type drop default;
