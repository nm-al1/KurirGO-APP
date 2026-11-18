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
    if (search ? input.query.trim().length < 3 || input.query.length > 200 :
      typeof input.lat !== "number" || typeof input.lng !== "number" || !Number.isFinite(input.lat) || !Number.isFinite(input.lng) || Math.abs(input.lat)>90 || Math.abs(input.lng)>180)
      return reply(400, {error: "Lokasi tidak valid"});
    const {data: allowed, error: rateError} = await userClient.rpc("courier_geocode_allowed");
    if (rateError || !allowed) return reply(429, {error: "Terlalu banyak pencarian. Coba lagi nanti."});
    const key = Deno.env.get("GEOAPIFY_API_KEY");
    if (!key) return reply(503, {error: "Layanan alamat belum dikonfigurasi"});
    const url = new URL(`https://api.geoapify.com/v1/geocode/${search ? 'autocomplete' : 'reverse'}`);
    url.search = new URLSearchParams({apiKey: key, format:"json", lang:"id", ...(search ?
      {text:input.query.trim(), filter:"countrycode:id", bias:"proximity:119.435,-5.156", limit:"5"} :
      {lat:String(input.lat), lon:String(input.lng)})}).toString();
    const response = await fetch(url, {signal: AbortSignal.timeout(10000)});
    if (!response.ok) return reply(response.status === 429 ? 429 : 502, {error:"Layanan alamat tidak tersedia"});
    const body = await response.json();
    return reply(200, {results:(body.results ?? []).map((v: any) => ({lat:v.lat, lon:v.lon, formatted:v.formatted}))});
  } catch { return reply(502, {error:"Alamat belum dapat dimuat"}); }
});
