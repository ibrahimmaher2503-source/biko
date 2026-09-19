import { createClient } from "https://esm.sh/@supabase/supabase-js@2.57.4";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (request.method !== "POST") return json({ error: "POST required" }, 405);

  const authorization = request.headers.get("Authorization");
  const token = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!token || !supabaseUrl || !anonKey || !serviceKey) {
    return json({ error: "Authenticated service unavailable" }, 401);
  }

  // Edge config verifies JWTs; getUser verifies the presented token again before
  // any RPC or Auth Admin call and keeps actor identity out of request JSON.
  const userClient = createClient(supabaseUrl, anonKey, {
    auth: { persistSession: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data: { user }, error: userError } = await userClient.auth.getUser(token);
  if (userError || !user) return json({ error: "Invalid session" }, 401);

  const serviceClient = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });
  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const action = body.action;
  const rpcActions: Record<string, string> = {
    create_role: "admin_create_role",
    rename_role: "admin_rename_role",
    set_role_permissions: "admin_set_role_permissions",
    assign_role: "admin_assign_staff_role",
    revoke_role: "admin_revoke_staff_role",
    update_status: "admin_update_staff_status",
  };
  const rpc = rpcActions[String(action)];
  const reason = typeof body.reason === "string" ? body.reason : null;

  if (rpc) {
    const input = {
      p_code: body.code ?? body.p_code,
      p_name: body.name ?? body.p_name,
      p_scope_type: body.scope_type ?? body.p_scope_type,
      p_permission_codes: body.permission_codes ?? body.p_permission_codes,
      p_role_id: body.role_id ?? body.p_role_id,
      p_target_user_id: body.target_user_id ?? body.p_target_user_id,
      p_office_id: body.office_id ?? body.p_office_id,
      p_status: body.status ?? body.p_status,
      p_reason: reason,
    };
    const { data, error } = await userClient.rpc(rpc, input);
    if (error) return json({ error: error.message }, error.code === "42501" ? 403 : 400);
    return json({ data });
  }

  if (action !== "create_staff" && action !== "invite_staff") {
    return json({ error: "Unsupported admin-staff action" }, 400);
  }
  if (typeof body.email !== "string" || !body.email.includes("@")
      || typeof body.role_id !== "string") {
    return json({ error: "email and role_id are required" }, 400);
  }

  const officeId = typeof body.office_id === "string" ? body.office_id : null;
  const { data: allowed, error: authorizationError } = await userClient.rpc(
    "admin_can_create_staff",
    { p_role_id: body.role_id, p_office_id: officeId },
  );
  if (authorizationError || allowed !== true) {
    return json({ error: authorizationError?.message ?? "Staff creation is not authorized" }, 403);
  }

  const fullName = typeof body.full_name === "string" ? body.full_name : "";
  let createdUser: { id: string } | null = null;
  if (action === "create_staff") {
    if (typeof body.password !== "string" || body.password.length < 8) {
      return json({ error: "password with at least 8 characters is required" }, 400);
    }
    const { data: created, error: createError } = await serviceClient.auth.admin.createUser({
      email: body.email,
      password: body.password,
      email_confirm: true,
      user_metadata: { full_name: fullName },
    });
    if (createError || !created.user) {
      return json({ error: createError?.message ?? "Unable to create Auth user" }, 400);
    }
    createdUser = created.user;
  } else {
    const { data: invited, error: inviteError } =
      await serviceClient.auth.admin.inviteUserByEmail(body.email, {
        data: { full_name: fullName },
      });
    if (inviteError || !invited.user) {
      return json({ error: inviteError?.message ?? "Unable to send invitation" }, 400);
    }
    createdUser = invited.user;
  }
  if (!createdUser) return json({ error: "Unable to provision Auth user" }, 400);

  const { data, error } = await userClient.rpc("admin_create_staff", {
    p_user_id: createdUser.id,
    p_full_name: fullName || null,
    p_role_id: body.role_id,
    p_office_id: typeof body.office_id === "string" ? body.office_id : null,
    p_reason: reason,
  });
  if (error) {
    await serviceClient.auth.admin.deleteUser(createdUser.id);
    return json({ error: error.message }, error.code === "42501" ? 403 : 400);
  }
  return json({
    data,
    invitation_sent: action === "invite_staff",
    user_id: createdUser.id,
  }, 201);
});
