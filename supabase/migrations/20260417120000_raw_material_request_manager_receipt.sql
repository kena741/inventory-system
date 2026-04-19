-- Stores manager verification after seller confirms purchase (meters, prices, good/damaged qty).
alter table public.raw_material_requests
  add column if not exists manager_receipt jsonb;

comment on column public.raw_material_requests.manager_receipt is
  'JSON: { lines: [{material_id, name, meters, unit_price, qty_good, qty_damaged}], recorded_at, recorded_by }';

-- Single PO decision: who approved/rejected and when (ISO8601 UTC recorded_at for sorting).
alter table public.raw_material_requests
  add column if not exists admin_approval jsonb;

comment on column public.raw_material_requests.admin_approval is
  'JSON: { decision: approved|rejected, actor_user_id: uuid, recorded_at: ISO-8601 UTC }. Order by (admin_approval->>''recorded_at'') desc';

-- workflow_audit: your schema uses jsonb[] (one jsonb object per event). Do not add a jsonb column here.
