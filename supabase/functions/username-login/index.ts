import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };
const reply = (status: number, body: object) => new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json", "Cache-Control": "no-store" } });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "POST") return reply(405, { error: "Method not allowed" });
  const started = Date.now();
  const rejected = async () => {
    await new Promise((resolve) => setTimeout(resolve, Math.max(0, 1000 - (Date.now() - started))));
    return reply(401, { error: "Username atau password tidak cocok, email belum diverifikasi, atau terlalu banyak percobaan. Coba lagi nanti." });
  };
  try {
    const text = await request.text();
    if (text.length > 4096) return rejected();
    const { username, password } = JSON.parse(text);
    if (typeof username !== "string" || !/^[a-z0-9_]{3,24}$/.test(username) || typeof password !== "string" || password.length < 8 || password.length > 1024) return rejected();
    const url = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const ip = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(`${serviceKey}:${ip}`));
    const ipHash = Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, "0")).join("");
    const { data: email, error } = await admin.rpc("courier_login_email", { login_name: username, ip_hash: ipHash });
    if (error || typeof email !== "string") return rejected();
    const auth = createClient(url, Deno.env.get("SUPABASE_ANON_KEY")!, { auth: { persistSession: false, autoRefreshToken: false } });
    const result = await auth.auth.signInWithPassword({ email, password });
    if (result.error || !result.data.session) return rejected();
    return reply(200, { refresh_token: result.data.session.refresh_token });
  } catch { return rejected(); }
});
