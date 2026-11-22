import { createClient } from "npm:@supabase/supabase-js@2.119.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json"
};

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse(405, { error: "Method not allowed." });
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization?.startsWith("Bearer ")) {
    return jsonResponse(401, { error: "Sign in before sharing a note." });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    console.error("Required Supabase function environment variables are missing.");
    return jsonResponse(500, { error: "Sharing is temporarily unavailable." });
  }

  const userClient = createClient(supabaseUrl, publishableKey, {
    global: { headers: { Authorization: authorization } },
    auth: { persistSession: false, autoRefreshToken: false }
  });
  const { data: userResult, error: userError } = await userClient.auth.getUser();
  const user = userResult?.user;
  if (userError || !user) {
    return jsonResponse(401, { error: "Your session expired. Sign in again." });
  }

  let body: { noteId?: unknown; email?: unknown; permission?: unknown };
  try {
    body = await request.json();
  } catch {
    return jsonResponse(400, { error: "Invalid request." });
  }

  const noteId = typeof body.noteId === "string" ? body.noteId : "";
  const email = typeof body.email === "string" ? body.email.trim().toLowerCase() : "";
  const permission = body.permission === "editor" ? "editor" : "viewer";
  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (!uuidPattern.test(noteId) || email.length > 320 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    return jsonResponse(400, { error: "Enter a valid email address." });
  }

  const { data: ownedNote, error: noteError } = await userClient
    .from("notes")
    .select("id")
    .eq("id", noteId)
    .eq("user_id", user.id)
    .maybeSingle();
  if (noteError || !ownedNote) {
    return jsonResponse(403, { error: "Only the note owner can share this note." });
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false }
  });
  const { data: recipientId, error: lookupError } = await adminClient
    .rpc("lookup_user_id_by_email", { p_email: email });

  if (lookupError) {
    console.error("Share recipient lookup failed:", lookupError);
    return jsonResponse(500, { error: "Could not find that NotesNow account." });
  }
  if (!recipientId) {
    return jsonResponse(404, { error: "No NotesNow account was found for that email. Ask them to create an account first." });
  }
  if (recipientId === user.id) {
    return jsonResponse(400, { error: "You already own this note." });
  }

  const { error: shareError } = await userClient
    .from("note_shares")
    .upsert({
      note_id: noteId,
      owner_id: user.id,
      shared_with_user_id: recipientId,
      shared_with_email: email,
      permission
    }, { onConflict: "note_id,shared_with_user_id" });

  if (shareError) {
    console.error("Could not save note share:", shareError);
    return jsonResponse(500, { error: "Could not share this note. Try again." });
  }

  return jsonResponse(200, { success: true });
});
