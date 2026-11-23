alter table public.books
  add column if not exists reading_path text;

alter table public.orders
  add column if not exists book_ids jsonb not null default '[]'::jsonb;

alter table public.books enable row level security;
grant select on public.books to anon, authenticated;

drop policy if exists "books_public_catalog" on public.books;
create policy "books_public_catalog"
  on public.books
  for select
  to anon, authenticated
  using (true);

alter table public.orders enable row level security;
grant select on public.orders to authenticated;
revoke insert, update, delete on public.orders from authenticated, anon;

drop policy if exists "orders_select_own" on public.orders;
create policy "orders_select_own"
  on public.orders
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "orders_insert_own" on public.orders;

create or replace function public.place_order(p_items jsonb)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  order_total numeric;
  purchased_book_ids jsonb;
  matched_items integer;
begin
  if auth.uid() is null then
    raise exception 'Authentication required';
  end if;

  if p_items is null
    or jsonb_typeof(p_items) <> 'array'
    or jsonb_array_length(p_items) = 0 then
    raise exception 'Order must contain at least one book';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_items) as entry(item)
    where jsonb_typeof(entry.item) <> 'object'
      or entry.item->>'book_id' is null
      or coalesce(entry.item->>'quantity', '') !~ '^[1-9][0-9]*$'
  ) then
    raise exception 'Invalid order item';
  end if;

  select
    sum(b.price * (entry.item->>'quantity')::integer),
    jsonb_agg(distinct to_jsonb(b.id::text)),
    count(*)
  into order_total, purchased_book_ids, matched_items
  from jsonb_array_elements(p_items) as entry(item)
  join public.books b on b.id::text = entry.item->>'book_id';

  if matched_items <> jsonb_array_length(p_items) then
    raise exception 'One or more books are unavailable';
  end if;

  insert into public.orders (user_id, total_price, status, book_ids)
  values (auth.uid(), order_total, 'en_attente', purchased_book_ids);
end;
$$;

revoke all on function public.place_order(jsonb) from public, anon;
grant execute on function public.place_order(jsonb) to authenticated;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('book-files', 'book-files', false)
on conflict (id) do update set public = false;

drop policy if exists "avatars_public_read" on storage.objects;
create policy "avatars_public_read"
  on storage.objects
  for select
  to anon, authenticated
  using (bucket_id = 'avatars');

drop policy if exists "avatars_insert_own" on storage.objects;
create policy "avatars_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "avatars_update_own" on storage.objects;
create policy "avatars_update_own"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "book_files_read_purchased" on storage.objects;
create policy "book_files_read_purchased"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'book-files'
    and exists (
      select 1
      from public.books b
      join public.orders o
        on o.book_ids @> jsonb_build_array(b.id::text)
      where b.reading_path = name
        and o.user_id = auth.uid()
    )
  );
