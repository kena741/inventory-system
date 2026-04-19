-- Optional enum; table may stay as text + CHECK. DB completion value is `fulfilled` (app shows completed).
-- Status values for raw_material_requests (matches Flutter RawMaterialRequestStatuses).
-- Legacy: 'purchased' is kept for older rows; app treats it like completed in closed lists.

do $$
begin
  create type public.raw_material_request_status as enum (
    'pending',
    'approved',
    'rejected',
    'fulfilled',
    'cancelled',
    'ordered',
    'seller_confirmed',
    'purchased'
  );
exception
  when duplicate_object then null;
end $$;

comment on type public.raw_material_request_status is
  'Purchase request status for public.raw_material_requests.status (fulfilled = receipt done; app maps to completed)';

-- Optional: switch column from text to enum (run only after all rows use valid values).
-- alter table public.raw_material_requests
--   alter column status drop default;
-- alter table public.raw_material_requests
--   alter column status type public.raw_material_request_status
--   using status::text::public.raw_material_request_status;
-- alter table public.raw_material_requests
--   alter column status set default 'pending'::public.raw_material_request_status;
