-- Admin-only operations used by the browser console. Keep auth.users private
-- and expose only the customer fields needed by administrators.
create or replace function public.get_admin_users()
returns table (
  user_id uuid,
  email text,
  full_name text,
  phone text,
  order_count bigint,
  created_at timestamptz,
  last_sign_in_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not public.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  return query
  select
    u.id,
    u.email::text,
    nullif(u.raw_user_meta_data ->> 'full_name', ''),
    nullif(u.raw_user_meta_data ->> 'phone', ''),
    user_orders.order_count,
    u.created_at,
    u.last_sign_in_at
  from auth.users u
  cross join lateral (
    select count(*)::bigint as order_count
    from public.orders o
    where o.user_id = u.id
  ) user_orders
  order by u.created_at desc;
end;
$$;

revoke all on function public.get_admin_users() from public, anon;
grant execute on function public.get_admin_users() to authenticated;

create or replace function public.admin_update_user_profile(
  p_user_id uuid,
  p_full_name text,
  p_phone text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  updated_count integer;
begin
  if not public.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  update auth.users
  set raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object(
    'full_name', nullif(btrim(p_full_name), ''),
    'phone', nullif(btrim(p_phone), '')
  )
  where id = p_user_id;

  get diagnostics updated_count = row_count;
  if updated_count = 0 then
    raise exception 'User not found' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.admin_update_user_profile(uuid, text, text) from public, anon;
grant execute on function public.admin_update_user_profile(uuid, text, text) to authenticated;

create or replace function public.get_admin_order_statuses()
returns text[]
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  status_type_oid oid;
  status_values text[];
begin
  if not public.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  select a.atttypid
  into status_type_oid
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.orders'::regclass
    and a.attname = 'status'
    and not a.attisdropped;

  if status_type_oid is null then
    raise exception 'Order status column not found' using errcode = '42703';
  end if;

  if exists (select 1 from pg_catalog.pg_type t where t.oid = status_type_oid and t.typtype = 'e') then
    select array_agg(e.enumlabel order by e.enumsortorder)
    into status_values
    from pg_catalog.pg_enum e
    where e.enumtypid = status_type_oid;
  else
    status_values := array['en_attente', 'confirmee', 'expediee', 'livree', 'annulee'];
  end if;

  return status_values;
end;
$$;

revoke all on function public.get_admin_order_statuses() from public, anon;
grant execute on function public.get_admin_order_statuses() to authenticated;

create or replace function public.admin_update_order_status(
  p_order_id text,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  status_type text;
  status_type_oid oid;
  valid_statuses text[];
  updated_count integer;
begin
  if not public.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  select pg_catalog.format_type(a.atttypid, a.atttypmod), a.atttypid
  into status_type, status_type_oid
  from pg_catalog.pg_attribute a
  where a.attrelid = 'public.orders'::regclass
    and a.attname = 'status'
    and not a.attisdropped;

  if status_type is null then
    raise exception 'Order status column not found' using errcode = '42703';
  end if;

  if exists (select 1 from pg_catalog.pg_type t where t.oid = status_type_oid and t.typtype = 'e') then
    select array_agg(e.enumlabel order by e.enumsortorder)
    into valid_statuses
    from pg_catalog.pg_enum e
    where e.enumtypid = status_type_oid;
  else
    valid_statuses := array['en_attente', 'confirmee', 'expediee', 'livree', 'annulee'];
  end if;

  if p_status is null or not (p_status = any(valid_statuses)) then
    raise exception 'Invalid order status' using errcode = '22023';
  end if;

  execute pg_catalog.format(
    'update public.orders set status = $1::%s where id::text = $2',
    status_type
  ) using p_status, p_order_id;

  get diagnostics updated_count = row_count;
  if updated_count = 0 then
    raise exception 'Order not found' using errcode = 'P0002';
  end if;
end;
$$;

revoke all on function public.admin_update_order_status(text, text) from public, anon;
grant execute on function public.admin_update_order_status(text, text) to authenticated;
