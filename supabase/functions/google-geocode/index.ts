import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };
const reply = (status: number, body: object) => new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply(405, {error: "Method not allowed"});
  try {
    const auth = req.headers.get("Authorization") ?? "";
    const userClient = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {global:{headers:{Authorization:auth}}});
    const {data:{user}, error} = await userClient.auth.getUser();
    if (error || !user) return reply(401, {error: "Masuk dahulu"});
    const text = await req.text();
    if (text.length > 2048) return reply(400, {error: "Input terlalu panjang"});
    const input = JSON.parse(text);
    const search = typeof input.query === "string";
    const details = typeof input.placeId === "string";
    if (search || details) {
      if (typeof input.sessionToken !== 'string' || !/^[a-f0-9-]{36}$/.test(input.sessionToken)) return reply(400, {error:"Sesi pencarian tidak valid"});
      if (search ? input.query.trim().length < 3 || input.query.length > 200 : input.placeId.length < 1 || input.placeId.length > 256) return reply(400, {error:"Pencarian tidak valid"});
    } else if (typeof input.lat !== 'number' || typeof input.lng !== 'number' || !Number.isFinite(input.lat) || !Number.isFinite(input.lng) || Math.abs(input.lat)>90 || Math.abs(input.lng)>180) return reply(400, {error:"Lokasi tidak valid"});
    const {data: allowed, error: rateError} = await userClient.rpc("courier_geocode_allowed");
    if (rateError || !allowed) return reply(429, {error: "Terlalu banyak pencarian. Coba lagi nanti."});
    const key = Deno.env.get("GOOGLE_MAPS_SERVER_KEY");
    if (!key) return reply(503, {error:"Layanan Google Maps belum dikonfigurasi"});
    let response: Response;
    if (search) {
      response = await fetch('https://places.googleapis.com/v1/places:autocomplete', {
        method:'POST', signal:AbortSignal.timeout(10000),
        headers:{'Content-Type':'application/json','X-Goog-Api-Key':key},
        body:JSON.stringify({input:input.query.trim(), languageCode:'id', includedRegionCodes:['id'],
          locationBias:{circle:{center:{latitude:-5.156,longitude:119.435},radius:50000}},sessionToken:input.sessionToken})
      });
    } else if (details) {
      response = await fetch(`https://places.googleapis.com/v1/places/${encodeURIComponent(input.placeId)}?languageCode=id&sessionToken=${encodeURIComponent(input.sessionToken)}`, {
        signal:AbortSignal.timeout(10000),headers:{'X-Goog-Api-Key':key,'X-Goog-FieldMask':'id,location'}
      });
    } else {
      const params = new URLSearchParams({latlng:`${input.lat},${input.lng}`, language:'id',key});
      response = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?${params}`,{signal:AbortSignal.timeout(10000)});
    }
    if (!response.ok) return reply(response.status === 429 ? 429 : 502, {error:"Google belum dapat melayani pencarian. Periksa konfigurasi API dan billing."});
    const body = await response.json();
    if (search) return reply(200,{results:(body.suggestions ?? []).filter((v:any)=>v.placePrediction).slice(0,5).map((v:any)=>({placeId:v.placePrediction.placeId,formatted:v.placePrediction.text?.text}))});
    if (details) {
      if (!body.location) return reply(200,{results:[]});
      const params = new URLSearchParams({latlng:`${body.location.latitude},${body.location.longitude}`,language:'id',key});
      const addressResponse = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?${params}`,{signal:AbortSignal.timeout(10000)});
      if (!addressResponse.ok) return reply(502,{error:"Alamat tempat belum dapat dimuat. Coba lagi."});
      const address = await addressResponse.json();
      if (address.status !== 'OK' && address.status !== 'ZERO_RESULTS') return reply(502,{error:"Periksa konfigurasi Geocoding API dan billing."});
      return reply(200,{results:[{placeId:body.id,lat:body.location.latitude,lon:body.location.longitude,formatted:address.results?.[0]?.formatted_address ?? null}]});
    }
    if (body.status !== 'OK' && body.status !== 'ZERO_RESULTS') return reply(502,{error:"Alamat Google belum tersedia. Periksa konfigurasi Geocoding API dan billing."});
    return reply(200,{results:(body.results ?? []).slice(0,1).map((v:any)=>({lat:input.lat,lon:input.lng,formatted:v.formatted_address}))});
  } catch { return reply(502,{error:"Alamat belum dapat dimuat"}); }
});
