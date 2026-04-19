-- Merges your original statuses with app workflow values.
-- DB uses fulfilled (app maps to completed in UI). Adds ordered, seller_confirmed, purchased.

alter table public.raw_material_requests
  drop constraint if exists raw_material_requests_status_check;

alter table public.raw_material_requests
  add constraint raw_material_requests_status_check
  check (
    status in (
      'pending',
      'approved',
      'rejected',
      'fulfilled',
      'cancelled',
      'ordered',
      'seller_confirmed',
      'purchased'
    )
  );
