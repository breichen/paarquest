// Wird von Database Webhooks (tasks + purchases, INSERT und UPDATE) aufgerufen
// und schickt per FCM einen Push an die richtige Person.
import { createClient } from "npm:@supabase/supabase-js@2";

const sa = JSON.parse(Deno.env.get("FIREBASE_SERVICE_ACCOUNT")!);
const sb = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const b64url = (s: string) =>
  btoa(s).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");

async function accessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const head = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const data = `${head}.${claim}`;
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(data),
  );
  const sigStr = b64url(String.fromCharCode(...new Uint8Array(sig)));
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${data}.${sigStr}`,
    }),
  });
  return (await res.json()).access_token;
}

const hours = (h: number) =>
  h % 24 === 0 ? `${h / 24} Tag${h === 24 ? "" : "e"}` : `${h} Std`;
const other = (n: string) => (n === "Benjamin" ? "Theresa" : "Benjamin");

type Msg = { to: string; title: string; body: string } | null;

function build(table: string, type: string, r: any, old: any): Msg {
  if (table === "tasks") {
    if (type === "INSERT") {
      return { to: r.assignee, title: `Neue Aufgabe von ${r.creator}`, body: `${r.title} (${r.coins} Münzen, ${hours(r.hours)})` };
    }
    if (type !== "UPDATE" || old.status === r.status) return null;
    switch (r.status) {
      case "countered":
        return { to: r.creator, title: `${r.assignee} macht einen Vorschlag`, body: `${r.title}: ${r.coins} Münzen, ${hours(r.hours)}` };
      case "accepted":
        return old.status === "pending"
          ? { to: r.creator, title: `${r.assignee} hat angenommen`, body: r.title }
          : { to: r.assignee, title: `${r.creator} akzeptiert deinen Vorschlag`, body: r.title };
      case "declined":
        return { to: r.creator, title: `${r.assignee} hat abgelehnt`, body: r.title };
      case "discarded":
        return { to: r.assignee, title: `${r.creator} hat den Vorschlag verworfen`, body: r.title };
      case "done":
        return { to: r.creator, title: `${r.assignee} hat erledigt`, body: `${r.title} (+${r.coins} Münzen)` };
      case "cancelled":
        return { to: other(r.cancelled_by), title: `${r.cancelled_by} hat abgebrochen`, body: r.title };
    }
  }
  if (table === "purchases") {
    if (type === "INSERT") {
      return { to: other(r.buyer), title: `${r.buyer} hat etwas eingelöst`, body: `${r.reward} (${r.cost} Münzen)` };
    }
    if (type === "UPDATE" && old.status !== r.status && r.status === "fulfilled") {
      return { to: r.buyer, title: `${other(r.buyer)} hat erfüllt`, body: r.reward };
    }
  }
  return null;
}

Deno.serve(async (req) => {
  const p = await req.json();
  const msg = build(p.table, p.type, p.record, p.old_record);
  if (!msg) return new Response("skip");

  const { data } = await sb.from("device_tokens").select("token").eq("user_name", msg.to).maybeSingle();
  if (!data) return new Response("kein Gerät registriert");

  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${await accessToken()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: data.token,
          notification: { title: msg.title, body: msg.body },
          android: { priority: "HIGH", notification: { channel_id: "paarquest" } },
        },
      }),
    },
  );
  return new Response(await res.text(), { status: res.status });
});
