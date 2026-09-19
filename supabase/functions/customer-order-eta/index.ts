import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "content-type": "application/json; charset=utf-8" },
});

const first = (value: unknown) => Array.isArray(value) ? value[0] as Record<string, unknown> | undefined : undefined;

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const authorization = request.headers.get("authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const googleKey = Deno.env.get("GOOGLE_MAPS_SERVER_API_KEY");
  if (!authorization || !supabaseUrl || !anonKey || !serviceKey) return json({ error: "Authentication required" }, 401);
  if (!googleKey) return json({ error: "Google Routes configuration unavailable" }, 503);

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data: { user } } = await userClient.auth.getUser();
  if (!user) return json({ error: "Authentication required" }, 401);

  try {
    const { order_id: orderId } = await request.json();
    if (typeof orderId !== "string" || !/^[0-9a-f-]{36}$/i.test(orderId)) {
      return json({ error: "Invalid order" }, 400);
    }
    const reserved = first((await userClient.rpc("reserve_customer_order_eta", {
      p_order_id: orderId,
    })).data);
    if (!reserved) return json({ error: "Tracking unavailable" }, 404);
    if (!reserved.refresh_required) {
      const tracking = first((await userClient.rpc("get_customer_order_tracking", {
        p_order_id: orderId,
      })).data);
      return tracking ? json(tracking) : json({ error: "Tracking unavailable" }, 404);
    }

    const response = await fetch("https://routes.googleapis.com/directions/v2:computeRoutes", {
      method: "POST",
      signal: AbortSignal.timeout(10000),
      headers: {
        "content-type": "application/json",
        "X-Goog-Api-Key": googleKey,
        "X-Goog-FieldMask": "routes.duration",
      },
      body: JSON.stringify({
        origin: { location: { latLng: { latitude: reserved.latitude, longitude: reserved.longitude } } },
        destination: { location: { latLng: { latitude: reserved.target_latitude, longitude: reserved.target_longitude } } },
        travelMode: "TWO_WHEELER",
        routingPreference: "TRAFFIC_UNAWARE",
        computeAlternativeRoutes: false,
      }),
    });
    if (!response.ok) return json({ error: "Route calculation unavailable" }, 502);
    const route = (await response.json()).routes?.[0];
    const duration = String(route?.duration ?? "");
    if (!/^\d+(?:\.\d+)?s$/.test(duration)) return json({ error: "No usable route found" }, 422);
    const etaSeconds = Math.ceil(Number(duration.slice(0, -1)));
    if (!Number.isFinite(etaSeconds) || etaSeconds <= 0) return json({ error: "No usable route found" }, 422);

    // Re-authorize after the paid call. A completed/cancelled order must never
    // receive an in-flight route response.
    const current = first((await userClient.rpc("get_customer_order_tracking", {
      p_order_id: orderId,
    })).data);
    if (!current) return json({ error: "Tracking unavailable" }, 404);

    const serviceClient = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });
    const { error: saveError } = await serviceClient.from("order_driver_tracking")
      .update({ eta_seconds: etaSeconds, eta_updated_at: new Date().toISOString(), eta_refresh_started_at: null, eta_reservation_id: null, updated_at: new Date().toISOString() })
      .eq("order_id", orderId)
      .eq("eta_reservation_id", reserved.eta_reservation_id);
    if (saveError) return json({ error: "Tracking unavailable" }, 409);
    const fresh = first((await userClient.rpc("get_customer_order_tracking", {
      p_order_id: orderId,
    })).data);
    return fresh ? json(fresh) : json({ error: "Tracking unavailable" }, 404);
  } catch (_) {
    return json({ error: "ETA request failed" }, 502);
  }
});
