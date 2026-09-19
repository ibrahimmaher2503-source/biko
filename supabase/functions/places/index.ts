import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "content-type": "application/json; charset=utf-8" },
});

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const authorization = request.headers.get("authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const googleKey = Deno.env.get("GOOGLE_MAPS_SERVER_API_KEY");
  if (!authorization || !supabaseUrl || !anonKey) return json({ error: "Authentication required" }, 401);
  if (!googleKey) return json({ error: "Google Places configuration unavailable" }, 503);

  const supabase = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false },
  });
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return json({ error: "Authentication required" }, 401);

  try {
    const body = await request.json();
    const sessionToken = String(body.session_token ?? "").trim();
    if (!sessionToken || sessionToken.length > 128) return json({ error: "Invalid session token" }, 400);

    if (body.action === "autocomplete") {
      const input = String(body.input ?? "").trim();
      if (input.length < 3 || input.length > 160) return json({ suggestions: [] });
      const response = await fetch("https://places.googleapis.com/v1/places:autocomplete", {
        method: "POST",
        signal: AbortSignal.timeout(8000),
        headers: {
          "content-type": "application/json",
          "X-Goog-Api-Key": googleKey,
          "X-Goog-FieldMask": "suggestions.placePrediction.placeId,suggestions.placePrediction.text.text",
        },
        body: JSON.stringify({
          input,
          sessionToken,
          languageCode: "ar",
          regionCode: "EG",
          includedRegionCodes: ["eg"],
        }),
      });
      if (!response.ok) return json({ error: "Places search unavailable" }, 502);
      const payload = await response.json();
      return json({
        suggestions: (payload.suggestions ?? []).flatMap((item: Record<string, unknown>) => {
          const prediction = item.placePrediction as Record<string, unknown> | undefined;
          const text = prediction?.text as Record<string, unknown> | undefined;
          return prediction?.placeId && text?.text
            ? [{ place_id: prediction.placeId, label: text.text }]
            : [];
        }).slice(0, 5),
      });
    }

    if (body.action === "details") {
      const placeId = String(body.place_id ?? "").trim();
      if (!placeId || placeId.length > 256) return json({ error: "Invalid place" }, 400);
      const url = new URL(`https://places.googleapis.com/v1/places/${encodeURIComponent(placeId)}`);
      url.searchParams.set("languageCode", "ar");
      url.searchParams.set("sessionToken", sessionToken);
      const response = await fetch(url, {
        signal: AbortSignal.timeout(8000),
        headers: {
          "X-Goog-Api-Key": googleKey,
          "X-Goog-FieldMask": "id,displayName,formattedAddress,location",
        },
      });
      if (!response.ok) return json({ error: "Place details unavailable" }, 502);
      const place = await response.json();
      return json({
        place_id: place.id,
        label: place.formattedAddress ?? place.displayName?.text,
        latitude: place.location?.latitude,
        longitude: place.location?.longitude,
      });
    }
    return json({ error: "Unsupported action" }, 400);
  } catch (_) {
    return json({ error: "Places request failed" }, 502);
  }
});
