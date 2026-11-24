-- Admin console access. Never put a service_role key in the browser app.
create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admin_users enable row level security;
grant select on public.admin_users to authenticated;
grant insert, update, delete on public.books to authenticated;
grant select on public.orders to authenticated;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.admin_users au where au.user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

drop policy if exists "admin_users_read_self" on public.admin_users;
create policy "admin_users_read_self"
  on public.admin_users for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "books_admin_insert" on public.books;
create policy "books_admin_insert" on public.books
  for insert to authenticated with check (public.is_admin());

drop policy if exists "books_admin_update" on public.books;
create policy "books_admin_update" on public.books
  for update to authenticated using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "books_admin_delete" on public.books;
create policy "books_admin_delete" on public.books
  for delete to authenticated using (public.is_admin());

drop policy if exists "orders_admin_read" on public.orders;
create policy "orders_admin_read" on public.orders
  for select to authenticated using (public.is_admin());

drop policy if exists "book_files_admin_read" on storage.objects;
create policy "book_files_admin_read" on storage.objects
  for select to authenticated using (
    bucket_id = 'book-files' and public.is_admin()
  );

drop policy if exists "book_files_admin_insert" on storage.objects;
create policy "book_files_admin_insert" on storage.objects
  for insert to authenticated with check (
    bucket_id = 'book-files' and public.is_admin()
  );

drop policy if exists "book_files_admin_update" on storage.objects;
create policy "book_files_admin_update" on storage.objects
  for update to authenticated using (
    bucket_id = 'book-files' and public.is_admin()
  ) with check (bucket_id = 'book-files' and public.is_admin());

drop policy if exists "book_files_admin_delete" on storage.objects;
create policy "book_files_admin_delete" on storage.objects
  for delete to authenticated using (
    bucket_id = 'book-files' and public.is_admin()
  );

-- Bootstrap once from the Supabase SQL editor after creating the admin account:
-- insert into public.admin_users (user_id)
-- select id from auth.users where lower(email) = lower('admin@example.com')
-- on conflict (user_id) do nothing;
