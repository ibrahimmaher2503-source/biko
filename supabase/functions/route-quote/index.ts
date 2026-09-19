import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "content-type": "application/json; charset=utf-8" },
});
const coordinate = (value: unknown, min: number, max: number) => {
  const number = Number(value);
  if (!Number.isFinite(number) || number < min || number > max) throw new Error("Invalid coordinate");
  return Number(number.toFixed(6));
};

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
    const body = await request.json();
    const pickupLat = coordinate(body.pickup_lat, -90, 90);
    const pickupLng = coordinate(body.pickup_lng, -180, 180);
    const destinationLat = coordinate(body.destination_lat, -90, 90);
    const destinationLng = coordinate(body.destination_lng, -180, 180);
    const serviceTypeId = String(body.service_type_id ?? "");

    const response = await fetch("https://routes.googleapis.com/directions/v2:computeRoutes", {
      method: "POST",
      signal: AbortSignal.timeout(10000),
      headers: {
        "content-type": "application/json",
        "X-Goog-Api-Key": googleKey,
        "X-Goog-FieldMask": "routes.distanceMeters,routes.duration,routes.polyline.encodedPolyline",
      },
      body: JSON.stringify({
        origin: { location: { latLng: { latitude: pickupLat, longitude: pickupLng } } },
        destination: { location: { latLng: { latitude: destinationLat, longitude: destinationLng } } },
        travelMode: "TWO_WHEELER",
        routingPreference: "TRAFFIC_UNAWARE",
        computeAlternativeRoutes: false,
        polylineQuality: "OVERVIEW",
      }),
    });
    if (!response.ok) return json({ error: "Route calculation unavailable" }, 502);
    const payload = await response.json();
    const route = payload.routes?.[0];
    const durationSeconds = Math.ceil(Number(String(route?.duration ?? "").replace(/s$/, "")));
    if (!route?.distanceMeters || !durationSeconds || !route?.polyline?.encodedPolyline) {
      return json({ error: "No usable route found" }, 422);
    }

    const serviceClient = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });
    const { data, error } = await serviceClient.rpc("create_trusted_route_quote", {
      p_customer_id: user.id,
      p_service_type_id: serviceTypeId,
      p_pickup_lat: pickupLat,
      p_pickup_lng: pickupLng,
      p_destination_lat: destinationLat,
      p_destination_lng: destinationLng,
      p_distance_meters: route.distanceMeters,
      p_duration_seconds: durationSeconds,
      p_encoded_polyline: route.polyline.encodedPolyline,
    });
    if (error) {
      const unavailable = error.message.includes("Pricing configuration unavailable");
      return json({ error: unavailable ? "Pricing configuration unavailable" : "Route quote rejected" }, unavailable ? 503 : 422);
    }
    return json(Array.isArray(data) ? data[0] : data);
  } catch (_) {
    return json({ error: "Route quote request failed" }, 400);
  }
});
