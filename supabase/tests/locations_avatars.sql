begin;
insert into auth.users(id,email,raw_user_meta_data) values
('00000000-0000-4000-8000-000000000011','avatar1@example.test','{"username":"avatar_test_one","full_name":"Avatar One","phone":"08123456789"}'),
('00000000-0000-4000-8000-000000000012','avatar2@example.test','{"username":"avatar_test_two","full_name":"Avatar Two","phone":"08123456789"}');
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000011';
insert into storage.objects(bucket_id,name) values ('courier-avatars','00000000-0000-4000-8000-000000000011/test.jpg');
do $$ begin
 assert (select count(*) from storage.objects where bucket_id='courier-avatars')=1;
 for i in 1..30 loop assert public.courier_geocode_allowed(); end loop;
 assert not public.courier_geocode_allowed();
end $$;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000012';
do $$ declare affected integer; begin
 assert (select count(*) from storage.objects where bucket_id='courier-avatars')=0, 'Cross-account read';
 begin
  insert into storage.objects(bucket_id,name) values ('courier-avatars','00000000-0000-4000-8000-000000000011/bad.jpg');
  raise exception 'Cross-account insert permitted';
 exception when insufficient_privilege then null; end;
 assert public.courier_geocode_allowed(), 'Rate limit leaked across accounts';
end $$;
rollback;
