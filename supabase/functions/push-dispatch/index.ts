import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

type ServiceAccount = {
  client_email: string;
  private_key: string;
  project_id: string;
};
type Intent = {
  id: string;
  event_type: string;
  target_app_kind: string;
  target_type: string;
  order_id: string | null;
  offer_id: string | null;
  title: string;
  body: string;
  tokens: string[];
};

const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {
  status,
  headers: { "content-type": "application/json; charset=utf-8" },
});
const base64Url = (value: Uint8Array | string) => {
  const bytes = typeof value === "string" ? new TextEncoder().encode(value) : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll("=", "");
};
let cachedAccessToken: { value: string; expiresAt: number } | null = null;

async function accessToken(account: ServiceAccount) {
  if (cachedAccessToken && cachedAccessToken.expiresAt > Date.now() + 60_000) {
    return cachedAccessToken.value;
  }
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const pem = account.private_key.replace(/-----(BEGIN|END) PRIVATE KEY-----|\s/g, "");
  const keyBytes = Uint8Array.from(atob(pem), (character) => character.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyBytes,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const unsigned = `${header}.${claims}`;
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    signal: AbortSignal.timeout(8_000),
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64Url(new Uint8Array(signature))}`,
    }),
  });
  if (!response.ok) throw new Error("FCM_AUTH_UNAVAILABLE");
  const result = await response.json();
  cachedAccessToken = {
    value: String(result.access_token),
    expiresAt: Date.now() + Number(result.expires_in ?? 3600) * 1000,
  };
  return cachedAccessToken.value;
}

async function send(account: ServiceAccount, bearer: string, intent: Intent, token: string) {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(account.project_id)}/messages:send`,
    {
      method: "POST",
      signal: AbortSignal.timeout(8_000),
      headers: {
        authorization: `Bearer ${bearer}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: intent.title, body: intent.body },
          data: {
            notification_id: intent.id,
            event_type: intent.event_type,
            target_type: intent.target_type,
            order_id: intent.order_id ?? "",
            offer_id: intent.offer_id ?? "",
            title: intent.title,
            body: intent.body,
          },
          android: { notification: { channel_id: "biko_operational" } },
          apns: { payload: { aps: { sound: "default" } } },
        },
      }),
    },
  );
  if (response.ok) return { ok: true, invalid: false };
  const error = await response.json().catch(() => ({}));
  const details = error?.error?.details ?? [];
  const invalid = details.some((item: Record<string, unknown>) => item.errorCode === "UNREGISTERED");
  return { ok: false, invalid };
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const authorization = request.headers.get("authorization");
  if (!supabaseUrl || !serviceKey || authorization !== `Bearer ${serviceKey}`) {
    return json({ error: "Authentication required" }, 401);
  }
  const rawAccount = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");
  if (!rawAccount) return json({ error: "FCM configuration unavailable" }, 503);

  try {
    const account = JSON.parse(rawAccount) as ServiceAccount;
    if (!account.client_email || !account.private_key || !account.project_id) {
      return json({ error: "FCM configuration unavailable" }, 503);
    }
    const supabase = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false } });
    const { data, error } = await supabase.rpc("claim_notification_outbox", { p_limit: 5 });
    if (error) throw new Error("OUTBOX_CLAIM_FAILED");
    const intents = (data ?? []) as Intent[];
    if (!intents.length) return json({ claimed: 0, sent: 0, retryable: 0 });
    const bearer = await accessToken(account);
    let sent = 0;
    let retryable = 0;

    for (const intent of intents) {
      const results = await Promise.all(intent.tokens.map((token) => send(account, bearer, intent, token)));
      for (let index = 0; index < results.length; index++) {
        if (results[index].invalid) {
          await supabase.rpc("disable_push_token", {
            p_token: intent.tokens[index],
            p_app_kind: intent.target_app_kind,
          });
        }
      }
      const needsRetry = results.some((result) => !result.ok && !result.invalid);
      await supabase.rpc("complete_notification_outbox", {
        p_id: intent.id,
        p_success: !needsRetry,
        p_error_code: needsRetry ? "FCM_SEND_UNAVAILABLE" : null,
        p_retry_after_seconds: 30,
      });
      if (needsRetry) retryable++; else sent++;
    }
    return json({ claimed: intents.length, sent, retryable });
  } catch (error) {
    return json({ error: error instanceof Error ? error.message : "PUSH_DISPATCH_FAILED" }, 503);
  }
});
