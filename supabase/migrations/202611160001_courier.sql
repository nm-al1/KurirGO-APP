-- Account snapshots and a transaction journal keep delivery + payment atomic.
create table public.courier_state (
  owner uuid primary key references auth.users(id) on delete cascade,
  revision bigint not null default 0 check (revision >= 0),
  payload jsonb not null default '{"orders":[],"trips":[]}'::jsonb,
  updated_at timestamptz not null default now()
);
create table public.courier_operations (
  owner uuid not null references auth.users(id) on delete cascade,
  id uuid not null,
  revision bigint not null,
  payload_hash text not null,
  created_at timestamptz not null default now(),
  primary key (owner, id)
);
alter table public.courier_state enable row level security;
alter table public.courier_operations enable row level security;
create policy own_state on public.courier_state for select to authenticated using (owner = (select auth.uid()));
create policy own_operations on public.courier_operations for select to authenticated using (owner = (select auth.uid()));
revoke all on public.courier_state, public.courier_operations from anon, authenticated;
grant select on public.courier_state, public.courier_operations to authenticated;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table private.courier_usernames (
  owner uuid primary key references auth.users(id) on delete cascade,
  username text unique not null check (username ~ '^[a-z0-9_]{3,24}$')
);
create table private.login_attempts (
  key text primary key,
  started_at timestamptz not null,
  attempts integer not null
);

create function private.courier_profile() returns trigger
language plpgsql security definer set search_path = '' as $$
declare username text := lower(trim(new.raw_user_meta_data->>'username'));
begin
  if username is null or username !~ '^[a-z0-9_]{3,24}$'
     or length(trim(coalesce(new.raw_user_meta_data->>'full_name',''))) not between 1 and 100
     or coalesce(new.raw_user_meta_data->>'phone','') !~ '^0[0-9]{8,14}$' then
    raise exception 'Profil kurir tidak valid';
  end if;
  if tg_op = 'INSERT' then
    insert into private.courier_usernames values (new.id, username);
  elsif username is distinct from old.raw_user_meta_data->>'username' then
    raise exception 'Username tidak dapat diubah';
  end if;
  return new;
end $$;
create trigger courier_profile_insert after insert on auth.users for each row execute function private.courier_profile();
create trigger courier_profile_update before update of raw_user_meta_data on auth.users for each row execute function private.courier_profile();

create function public.courier_login_email(login_name text, ip_hash text) returns text
language plpgsql security definer set search_path = '' as $$
declare result text; attempts integer; bucket text;
begin
  if login_name !~ '^[a-z0-9_]{3,24}$' or length(ip_hash) != 64 then return null; end if;
  delete from private.login_attempts where started_at < now() - interval '1 day';
  foreach bucket in array array['user:' || login_name, 'ip:' || ip_hash] loop
    insert into private.login_attempts values (bucket, now(), 1)
    on conflict (key) do update set
      attempts = case when private.login_attempts.started_at < now() - interval '15 minutes' then 1 else private.login_attempts.attempts + 1 end,
      started_at = case when private.login_attempts.started_at < now() - interval '15 minutes' then now() else private.login_attempts.started_at end
    returning private.login_attempts.attempts into attempts;
    if attempts > (case when bucket like 'user:%' then 10 else 50 end) then return null; end if;
  end loop;
  select u.email into result from private.courier_usernames n join auth.users u on u.id = n.owner where n.username = login_name;
  return result;
end $$;
revoke all on function public.courier_login_email(text,text) from public, anon, authenticated;
grant execute on function public.courier_login_email(text,text) to service_role;

create function private.validate_courier_state(old_payload jsonb, new_payload jsonb) returns void
language plpgsql set search_path = '' as $$
declare o jsonb; previous jsonb; t jsonb; old_trip jsonb; ids jsonb; id text;
begin
  if jsonb_typeof(new_payload->'orders') is distinct from 'array' or jsonb_typeof(new_payload->'trips') is distinct from 'array'
    or pg_column_size(new_payload) > 20000000 then raise exception 'Data tidak valid atau terlalu besar'; end if;
  if (select count(*) != count(distinct x->>'id') from jsonb_array_elements(new_payload->'orders') x)
    or (select count(*) != count(distinct x->>'id') from jsonb_array_elements(new_payload->'trips') x) then raise exception 'ID duplikat'; end if;
  for previous in select value from jsonb_array_elements(old_payload->'orders') loop
    select value into o from jsonb_array_elements(new_payload->'orders') where value->>'id' = previous->>'id';
    if o is null then raise exception 'Pesanan tidak boleh dihapus'; end if;
    if previous->>'status' in ('completed','cancelled') and o != previous then raise exception 'Riwayat bersifat permanen'; end if;
    if previous->>'status' = 'active' and (o->>'status' not in ('active','completed') or
      (o - 'status' - 'payment' - 'completedAt') != (previous - 'status' - 'payment' - 'completedAt')) then raise exception 'Pesanan aktif tidak boleh diubah'; end if;
  end loop;
  for o in select value from jsonb_array_elements(new_payload->'orders') loop
    if (o->>'id')::uuid is null or coalesce(o->>'status','') not in ('waiting','active','completed','cancelled')
      or length(trim(coalesce(o->>'recipient',''))) not between 1 and 200
      or length(trim(coalesce(o->>'address',''))) not between 1 and 2000
      or length(trim(coalesce(o->>'items',''))) not between 1 and 2000
      or coalesce(o->>'phone','') !~ '^0[0-9]{8,14}$'
      or coalesce(o->>'boxes','') !~ '^[0-9]+$' or (o->>'boxes')::numeric not between 1 and 9999
      or coalesce(o->>'bill','') !~ '^[0-9]+$' or (o->>'bill')::numeric not between 0 and 999999999999
      or coalesce((o->>'lat')::numeric, 999) not between -90 and 90
      or coalesce((o->>'lng')::numeric, 999) not between -180 and 180
      or (o->>'createdAt')::timestamptz is null then raise exception 'Pesanan tidak valid'; end if;
    select value into previous from jsonb_array_elements(old_payload->'orders') where value->>'id' = o->>'id';
    if previous is null and o->>'status' != 'waiting' then raise exception 'Pesanan baru harus masuk antrean'; end if;
    if previous->>'status' = 'waiting' and o->>'status' = 'completed' then raise exception 'Pesanan belum masuk perjalanan'; end if;
    if o->>'status' in ('active','completed') and not exists(select 1 from jsonb_array_elements(new_payload->'trips') x where x->>'id' = o->>'tripId') then raise exception 'Perjalanan tidak ditemukan'; end if;
    if o->>'status' = 'completed' then
      if (o->>'completedAt')::timestamptz is null or coalesce(o->'payment'->>'method','') not in ('cash','qris','transfer')
        or coalesce(o->'payment'->>'received','') !~ '^[0-9]+$'
        or (o->'payment'->>'received')::numeric not between (o->>'bill')::numeric and 999999999999
        or (o->'payment'->>'method' != 'cash' and (length(trim(coalesce(o->'payment'->>'reference',''))) < 1 or o->'payment'->>'received' != o->>'bill')) then raise exception 'Pembayaran tidak valid'; end if;
    end if;
  end loop;
  for old_trip in select value from jsonb_array_elements(old_payload->'trips') loop
    select value into t from jsonb_array_elements(new_payload->'trips') where value->>'id' = old_trip->>'id';
    if t is null or (t - 'settledAt') != (old_trip - 'settledAt') or (old_trip->>'settledAt' is not null and t != old_trip) then raise exception 'Perjalanan tidak boleh ditulis ulang'; end if;
  end loop;
  if (select count(*) from jsonb_array_elements(new_payload->'trips') x where x->>'settledAt' is null) > 1 then raise exception 'Hanya satu perjalanan aktif'; end if;
  for t in select value from jsonb_array_elements(new_payload->'trips') loop
    if (t->>'id')::uuid is null or (t->>'startedAt')::timestamptz is null or jsonb_typeof(t->'stops') is distinct from 'array'
      or jsonb_array_length(t->'stops') not between 1 and 20 or jsonb_typeof(t->'geometry'->'route'->'legs') is distinct from 'array'
      or jsonb_array_length(t->'geometry'->'route'->'legs') != jsonb_array_length(t->'stops') + 1
      or coalesce((t->>'distance')::numeric,-1) < 0 then raise exception 'Rute tidak valid'; end if;
    ids := '[]'::jsonb;
    for o in select value from jsonb_array_elements(t->'stops') loop
      if jsonb_typeof(o) != 'array' or jsonb_array_length(o) < 1 then raise exception 'Stop kosong'; end if;
      ids := ids || o;
    end loop;
    if jsonb_array_length(ids) > 20 or (select count(*) != count(distinct value) from jsonb_array_elements_text(ids)) then raise exception 'Muatan duplikat atau terlalu banyak'; end if;
    for id in select value from jsonb_array_elements_text(ids) loop
      select value into o from jsonb_array_elements(new_payload->'orders') where value->>'id' = id;
      if o is null or o->>'tripId' is distinct from t->>'id' or o->>'status' not in ('active','completed') then raise exception 'Muatan tidak sesuai'; end if;
      if t->>'settledAt' is not null and o->>'status' != 'completed' then raise exception 'Muatan belum selesai'; end if;
    end loop;
    if exists(select 1 from jsonb_array_elements(new_payload->'orders') x where x->>'tripId' = t->>'id' and not ids ? (x->>'id')) then raise exception 'Pesanan tidak tercantum dalam rute'; end if;
    -- Completed orders must remain a prefix of the unloading sequence.
    if exists(select 1 from jsonb_array_elements_text(ids) with ordinality a(id,n)
      join jsonb_array_elements(new_payload->'orders') x on x->>'id' = a.id
      where x->>'status' = 'active' and exists(select 1 from jsonb_array_elements_text(ids) with ordinality b(id,n)
        join jsonb_array_elements(new_payload->'orders') y on y->>'id' = b.id where b.n > a.n and y->>'status' = 'completed')) then raise exception 'Urutan LIFO tidak sesuai'; end if;
  end loop;
end $$;

create function public.apply_courier_state(operation_id uuid, expected_revision bigint, new_payload jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare user_id uuid := auth.uid(); current_state public.courier_state; previous_op public.courier_operations;
begin
  if user_id is null then raise exception 'Login diperlukan'; end if;
  insert into public.courier_state(owner) values (user_id) on conflict do nothing;
  select * into current_state from public.courier_state where owner = user_id for update;
  select * into previous_op from public.courier_operations where owner = user_id and id = operation_id;
  if found then
    if previous_op.payload_hash != md5(new_payload::text) or previous_op.revision != expected_revision + 1 then raise exception 'ID operasi sudah dipakai'; end if;
    return jsonb_build_object('revision', previous_op.revision, 'conflict', false);
  end if;
  if current_state.revision != expected_revision then return jsonb_build_object('conflict', true, 'revision', current_state.revision); end if;
  perform private.validate_courier_state(current_state.payload, new_payload);
  update public.courier_state set payload = new_payload, revision = expected_revision + 1, updated_at = now() where owner = user_id;
  insert into public.courier_operations(owner,id,revision,payload_hash) values (user_id,operation_id,expected_revision + 1,md5(new_payload::text));
  return jsonb_build_object('revision', expected_revision + 1, 'conflict', false);
end $$;
revoke all on function public.apply_courier_state(uuid,bigint,jsonb) from public, anon;
grant execute on function public.apply_courier_state(uuid,bigint,jsonb) to authenticated;
