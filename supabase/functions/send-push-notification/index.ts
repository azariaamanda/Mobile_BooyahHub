// Supabase Edge Function: send-push-notification
// Dipanggil via Supabase Webhook saat ada INSERT ke tabel `notifikasi`
//
// Setup:
// 1. Supabase Dashboard → Database → Webhooks → Create Webhook
//    - Table: notifikasi, Event: INSERT
//    - URL: https://<project>.supabase.co/functions/v1/send-push-notification
//    - HTTP Method: POST
//
// 2. Supabase Dashboard → Settings → Edge Functions → Secrets
//    - FIREBASE_SERVICE_ACCOUNT = <isi JSON service account Firebase, minify ke 1 baris>

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.15.4/index.ts";

async function getFcmAccessToken(serviceAccount: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const privateKey = await jose.importPKCS8(serviceAccount.private_key, "RS256");
  const jwt = await new jose.SignJWT(payload)
    .setProtectedHeader({ alg: "RS256" })
    .sign(privateKey);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await res.json();
  return data.access_token as string;
}

serve(async (req) => {
  try {
    const body = await req.json();
    const record = body.record as Record<string, unknown>;

    if (!record) {
      return new Response("No record", { status: 400 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Cari FCM token target
    let tokenQuery = supabase.from("fcm_tokens").select("token");

    if (record.target_id_akun) {
      tokenQuery = tokenQuery.eq("akun_id", record.target_id_akun);
    } else if (record.target_role) {
      // Cari semua akun dengan role tersebut
      const { data: akuns } = await supabase
        .from("akun")
        .select("id_akun")
        .eq("role", record.target_role);

      if (!akuns || akuns.length === 0) {
        return new Response("No target accounts", { status: 200 });
      }

      const ids = akuns.map((a: Record<string, number>) => a.id_akun);
      tokenQuery = tokenQuery.in("akun_id", ids);
    } else {
      return new Response("No target specified", { status: 200 });
    }

    const { data: tokens } = await tokenQuery;
    if (!tokens || tokens.length === 0) {
      return new Response("No FCM tokens found", { status: 200 });
    }

    const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountRaw) {
      return new Response("FIREBASE_SERVICE_ACCOUNT not set", { status: 500 });
    }

    const serviceAccount = JSON.parse(serviceAccountRaw);
    const accessToken = await getFcmAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id as string;

    // Kirim ke setiap token
    const results = await Promise.allSettled(
      tokens.map(async (row: Record<string, string>) => {
        await fetch(
          `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
          {
            method: "POST",
            headers: {
              Authorization: `Bearer ${accessToken}`,
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              message: {
                token: row.token,
                notification: {
                  title: record.judul as string,
                  body: record.pesan as string,
                },
                android: {
                  priority: "high",
                  notification: { sound: "default" },
                },
                data: record.data
                  ? Object.fromEntries(
                      Object.entries(record.data as Record<string, unknown>).map(
                        ([k, v]) => [k, String(v)]
                      )
                    )
                  : {},
              },
            }),
          }
        );
      })
    );

    const sent = results.filter((r) => r.status === "fulfilled").length;
    return new Response(
      JSON.stringify({ success: true, sent, total: tokens.length }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
