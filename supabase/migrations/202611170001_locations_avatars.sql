insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('courier-avatars', 'courier-avatars', false, 2097152, array['image/jpeg'])
on conflict (id) do nothing;
create policy courier_avatar_read on storage.objects for select to authenticated
using (bucket_id = 'courier-avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy courier_avatar_insert on storage.objects for insert to authenticated
with check (bucket_id = 'courier-avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy courier_avatar_delete on storage.objects for delete to authenticated
using (bucket_id = 'courier-avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create table private.geocode_limits (owner uuid primary key references auth.users(id) on delete cascade, window_start timestamptz not null, requests integer not null);
create or replace function public.courier_geocode_allowed() returns boolean
language plpgsql security definer set search_path = '' as $$
declare count_now integer;
begin
  if auth.uid() is null then return false; end if;
  insert into private.geocode_limits values (auth.uid(), now(), 1)
  on conflict (owner) do update set
    requests = case when private.geocode_limits.window_start < now() - interval '1 minute' then 1 else private.geocode_limits.requests + 1 end,
    window_start = case when private.geocode_limits.window_start < now() - interval '1 minute' then now() else private.geocode_limits.window_start end
  returning requests into count_now;
  return count_now <= 30;
end $$;
revoke all on function public.courier_geocode_allowed() from public, anon;
grant execute on function public.courier_geocode_allowed() to authenticated;
