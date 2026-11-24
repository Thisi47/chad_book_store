-- Expose the live public schema to authorized admins for schema-driven forms.
create or replace function public.get_admin_schema()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  schema_json jsonb;
begin
  if not public.is_admin() then
    raise exception 'Admin access required' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'tables', coalesce(jsonb_agg(
      jsonb_build_object(
        'name', t.table_name,
        'columns', (
          select coalesce(jsonb_agg(jsonb_build_object(
            'name', c.column_name,
            'type', c.data_type,
            'udt_name', c.udt_name,
            'nullable', c.is_nullable = 'YES',
            'default', c.column_default,
            'identity', c.is_identity = 'YES',
            'generated', c.is_generated <> 'NEVER',
            'ordinal', c.ordinal_position,
            'primary_key', exists (
              select 1
              from information_schema.key_column_usage pk
              join information_schema.table_constraints tc
                on tc.constraint_schema = pk.constraint_schema
               and tc.constraint_name = pk.constraint_name
               and tc.table_name = pk.table_name
              where tc.constraint_type = 'PRIMARY KEY'
                and pk.table_schema = c.table_schema
                and pk.table_name = c.table_name
                and pk.column_name = c.column_name
            )
          ) order by c.ordinal_position), '[]'::jsonb)
          from information_schema.columns c
          where c.table_schema = t.table_schema
            and c.table_name = t.table_name
        ),
        'foreign_keys', (
          select coalesce(jsonb_agg(jsonb_build_object(
            'column', k.column_name,
            'referenced_schema', r.table_schema,
            'referenced_table', r.table_name,
            'referenced_column', r.column_name,
            'constraint', k.constraint_name
          ) order by k.ordinal_position), '[]'::jsonb)
          from information_schema.key_column_usage k
          join information_schema.table_constraints tc
            on tc.constraint_schema = k.constraint_schema
           and tc.constraint_name = k.constraint_name
           and tc.table_name = k.table_name
          join information_schema.constraint_column_usage r
            on r.constraint_schema = k.constraint_schema
           and r.constraint_name = k.constraint_name
          where tc.constraint_type = 'FOREIGN KEY'
            and k.table_schema = t.table_schema
            and k.table_name = t.table_name
        )
      ) order by t.table_name
    ), '[]'::jsonb)
  ) into schema_json
  from information_schema.tables t
  where t.table_schema = 'public'
    and t.table_type = 'BASE TABLE';

  return schema_json;
end;
$$;

revoke all on function public.get_admin_schema() from public, anon;
grant execute on function public.get_admin_schema() to authenticated;
