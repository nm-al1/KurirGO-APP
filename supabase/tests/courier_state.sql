\set ON_ERROR_STOP on
begin;
insert into auth.users(id,email,raw_user_meta_data) values
('00000000-0000-4000-8000-000000000001', 'one@example.test', '{"username":"courier_one","full_name":"Test One","phone":"08123456789"}'),
('00000000-0000-4000-8000-000000000002', 'two@example.test', '{"username":"courier_two","full_name":"Test Two","phone":"08123456780"}');
set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000001';
do $$
declare payload jsonb := '{"orders":[],"trips":[]}'; response jsonb;
begin
  response := public.apply_courier_state('10000000-0000-4000-8000-000000000001',0,payload);
  assert response->>'revision' = '1';
  response := public.apply_courier_state('10000000-0000-4000-8000-000000000001',0,payload);
  assert response->>'revision' = '1', 'Retry must be idempotent';
  response := public.apply_courier_state('10000000-0000-4000-8000-000000000002',0,payload);
  assert response->>'conflict' = 'true', 'Stale revision must conflict';
  assert (select count(*) from public.courier_operations) = 1;
  begin
    update public.courier_state set revision = 900;
    raise exception 'Direct writes unexpectedly permitted';
  exception when insufficient_privilege then null; end;
  begin
    perform public.courier_login_email('courier_one', repeat('0',64));
    raise exception 'Private email lookup unexpectedly permitted';
  exception when insufficient_privilege then null; end;
end $$;
set local request.jwt.claim.sub = '00000000-0000-4000-8000-000000000002';
do $$ begin
  assert (select count(*) from public.courier_state) = 0, 'Cross-account read leaked';
  assert (select count(*) from public.courier_operations) = 0, 'Cross-account operation leaked';
end $$;
reset role;
do $$
declare initial jsonb; active jsonb; completed jsonb; settled jsonb; bad jsonb; o jsonb; t jsonb;
begin
  o := '{"id":"20000000-0000-4000-8000-000000000001","recipient":"Test","address":"Jalan Test 1","phone":"08123456789","items":"Brownies","boxes":3,"bill":150000,"lat":-5.15,"lng":119.45,"status":"waiting","createdAt":"2026-11-16T01:00:00Z"}';
  initial := jsonb_build_object('orders',jsonb_build_array(o),'trips','[]'::jsonb);
  perform private.validate_courier_state('{"orders":[],"trips":[]}', initial);
  t := '{"id":"30000000-0000-4000-8000-000000000001","startedAt":"2026-11-16T02:00:00Z","settledAt":null,"stops":[["20000000-0000-4000-8000-000000000001"]],"geometry":{"route":{"legs":[{},{}]}},"distance":1000}';
  o := o || '{"status":"active","tripId":"30000000-0000-4000-8000-000000000001"}';
  active := jsonb_build_object('orders',jsonb_build_array(o),'trips',jsonb_build_array(t));
  perform private.validate_courier_state(initial, active);
  o := o || '{"status":"completed","completedAt":"2026-11-16T03:00:00Z","payment":{"method":"cash","received":200000,"reference":""}}';
  completed := jsonb_build_object('orders',jsonb_build_array(o),'trips',jsonb_build_array(t));
  perform private.validate_courier_state(active, completed);
  bad := jsonb_set(completed, '{orders,0,payment,received}', '100000');
  begin
    perform private.validate_courier_state(active, bad);
    raise exception using errcode = 'ZX001', message = 'Underpayment accepted';
  exception when raise_exception then null; end;
  bad := jsonb_set(completed, '{orders,0,bill}', '1');
  begin
    perform private.validate_courier_state(completed, bad);
    raise exception using errcode = 'ZX001', message = 'History rewrite accepted';
  exception when raise_exception then null; end;
  settled := jsonb_set(completed, '{trips,0,settledAt}', '"2026-11-16T04:00:00Z"');
  perform private.validate_courier_state(completed, settled);
  begin
    perform private.validate_courier_state(active, jsonb_set(active, '{trips,0,settledAt}', '"2026-11-16T04:00:00Z"'));
    raise exception using errcode = 'ZX001', message = 'Premature settlement accepted';
  exception when raise_exception then null; end;
end $$;
do $$ declare email text; begin
  for i in 1..10 loop
    email := public.courier_login_email('courier_one', repeat('a',64));
    assert email = 'one@example.test';
  end loop;
  assert public.courier_login_email('courier_one',repeat('a',64)) is null, 'Rate limit failed';
  begin
    insert into auth.users(id,email,raw_user_meta_data) values ('00000000-0000-4000-8000-000000000003','duplicate@example.test','{"username":"courier_one","full_name":"Duplicate","phone":"08123456789"}');
    raise exception 'Duplicate username accepted';
  exception when unique_violation then null; end;
end $$;
rollback;
\echo 'PASS: owner isolation, denied direct writes, idempotency, conflicts, payment validation, immutable history, settlement, unique username, rate limiting'
