/**
 * Prova — trigger-tryon Edge Function
 *
 * Flow:
 * 1. Validate request and auth
 * 2. Get user's active photo + selected garment from DB
 * 3. Get signed URLs for both images
 * 4. Create tryon_job record (status: pending)
 * 5. Call HuggingFace IDM-VTON Space via Gradio API (async)
 * 6. Update job status to processing
 * 7. Return job_id to client
 * 8. When HF result arrives (via webhook or polling), store result
 *
 * NOTE: HuggingFace Gradio API is called in "predict" mode which
 * can be async via queue. We poll the job status from a separate
 * scheduled check or the client handles timeout gracefully.
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const HF_TOKEN = Deno.env.get("HF_TOKEN") ?? ""; // Optional, increases rate limits

// HuggingFace IDM-VTON Space endpoint
// Space: yisol/IDM-VTON
// Fallback: levihsu/OOTDiffusion
const HF_SPACE_URL = "https://yisol-idm-vton.hf.space";

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Auth check
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return errorResponse("Yetkisiz istek", 401);
    }

    // Create Supabase client with user's JWT to enforce RLS
    const userClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    // Also create admin client for storage operations
    const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) {
      return errorResponse("Kullanıcı doğrulanamadı", 401);
    }

    // Parse request body
    const { photo_id, garment_id } = await req.json();
    if (!photo_id || !garment_id) {
      return errorResponse("photo_id ve garment_id gereklidir", 400);
    }

    // Fetch user photo record (verify ownership via user_id)
    const { data: photoRecord, error: photoError } = await adminClient
      .from("user_photos")
      .select("storage_path, is_active")
      .eq("id", photo_id)
      .eq("user_id", user.id)
      .single();

    if (photoError || !photoRecord) {
      return errorResponse("Fotoğraf bulunamadı", 404);
    }

    // Fetch garment record
    const { data: garmentRecord, error: garmentError } = await adminClient
      .from("garments")
      .select("storage_path, name_tr")
      .eq("id", garment_id)
      .eq("is_active", true)
      .single();

    if (garmentError || !garmentRecord) {
      return errorResponse("Kıyafet bulunamadı", 404);
    }

    // Get signed URL for user photo (private bucket, 10 min expiry)
    const { data: personSignedUrl } = await adminClient.storage
      .from("user-photos")
      .createSignedUrl(photoRecord.storage_path, 600);

    if (!personSignedUrl?.signedUrl) {
      return errorResponse("Fotoğraf URL alınamadı", 500);
    }

    // Get public URL for garment (public bucket)
    const { data: garmentPublicUrl } = adminClient.storage
      .from("garment-images")
      .getPublicUrl(garmentRecord.storage_path);

    // Create tryon_job record
    const { data: job, error: jobError } = await adminClient
      .from("tryon_jobs")
      .insert({
        user_id: user.id,
        photo_id: photo_id,
        garment_id: garment_id,
        status: "pending",
      })
      .select()
      .single();

    if (jobError || !job) {
      return errorResponse("İş kaydı oluşturulamadı", 500);
    }

    // Fire-and-forget: call HuggingFace and update job async
    // We don't await this — client polls via Realtime
    callHuggingFaceAndComplete(
      adminClient,
      job.id,
      user.id,
      personSignedUrl.signedUrl,
      garmentPublicUrl.publicUrl
    ).catch(async (err) => {
      // Mark job as failed if HF call throws
      await adminClient
        .from("tryon_jobs")
        .update({ status: "failed", error_msg: err.message })
        .eq("id", job.id);
    });

    // Return job_id immediately — client listens via Realtime
    return new Response(
      JSON.stringify({ job_id: job.id }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("trigger-tryon error:", err);
    return errorResponse("Sunucu hatası", 500);
  }
});

/**
 * Call IDM-VTON via Gradio API and store result.
 * This runs asynchronously after the main response is sent.
 */
async function callHuggingFaceAndComplete(
  adminClient: ReturnType<typeof createClient>,
  jobId: string,
  userId: string,
  personImageUrl: string,
  garmentImageUrl: string
) {
  // Update job to processing
  await adminClient
    .from("tryon_jobs")
    .update({ status: "processing" })
    .eq("id", jobId);

  // -------------------------------------------------------
  // IDM-VTON Gradio API call
  // The Space accepts:
  //   fn_index: 0 (main try-on function)
  //   data: [person_img_url, garment_img_url, ...]
  // Returns: [result_image_base64, ...]
  // -------------------------------------------------------
  const gradioPayload = {
    data: [
      { url: personImageUrl },  // person image
      { url: garmentImageUrl }, // garment image
      true,  // is_checked (use auto-masking)
      true,  // is_checked_crop
      30,    // denoise_steps
      42,    // seed
    ],
  };

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  if (HF_TOKEN) {
    headers["Authorization"] = `Bearer ${HF_TOKEN}`;
  }

  // Submit to Gradio queue
  const submitResponse = await fetch(`${HF_SPACE_URL}/queue/join`, {
    method: "POST",
    headers,
    body: JSON.stringify({ ...gradioPayload, fn_index: 0 }),
  });

  if (!submitResponse.ok) {
    throw new Error(`HF submit failed: ${submitResponse.status}`);
  }

  const { event_id } = await submitResponse.json();

  // Poll for result (max 120 seconds)
  const resultImageBase64 = await pollGradioResult(event_id, headers);

  if (!resultImageBase64) {
    throw new Error("HuggingFace sonuç üretemedi");
  }

  // Convert base64 to Uint8Array and upload to storage
  const base64Data = resultImageBase64.replace(/^data:image\/\w+;base64,/, "");
  const binaryData = Uint8Array.from(atob(base64Data), (c) => c.charCodeAt(0));

  const resultPath = `${userId}/${jobId}.jpg`;

  const { error: uploadError } = await adminClient.storage
    .from("tryon-results")
    .upload(resultPath, binaryData, {
      contentType: "image/jpeg",
      upsert: true,
    });

  if (uploadError) {
    throw new Error(`Storage upload failed: ${uploadError.message}`);
  }

  // Create tryon_result record
  const { data: result, error: resultError } = await adminClient
    .from("tryon_results")
    .insert({
      job_id: jobId,
      user_id: userId,
      storage_path: resultPath,
    })
    .select()
    .single();

  if (resultError) {
    throw new Error(`Result record failed: ${resultError.message}`);
  }

  // Mark job completed
  await adminClient
    .from("tryon_jobs")
    .update({ status: "completed" })
    .eq("id", jobId);
}

/**
 * Poll Gradio /queue/status until completion or timeout.
 */
async function pollGradioResult(
  eventId: string,
  headers: Record<string, string>,
  maxWaitMs = 120_000
): Promise<string | null> {
  const startTime = Date.now();

  while (Date.now() - startTime < maxWaitMs) {
    await sleep(3000); // poll every 3 seconds

    const statusResponse = await fetch(
      `${HF_SPACE_URL}/queue/status?session_hash=${eventId}`,
      { headers }
    );

    if (!statusResponse.ok) continue;

    const status = await statusResponse.json();

    if (status.status === "COMPLETE") {
      // Extract image from output
      const output = status.output?.data?.[0];
      if (output?.url) {
        // Fetch the actual image bytes from the returned URL
        const imgResponse = await fetch(output.url);
        const arrayBuffer = await imgResponse.arrayBuffer();
        const uint8Array = new Uint8Array(arrayBuffer);
        const base64 = btoa(String.fromCharCode(...uint8Array));
        return `data:image/jpeg;base64,${base64}`;
      }
      if (output && typeof output === "string") {
        return output; // already base64
      }
      return null;
    }

    if (status.status === "FAILED") {
      throw new Error("HuggingFace işlemi başarısız");
    }

    // status === QUEUED | PROCESSING — keep polling
  }

  throw new Error("HuggingFace zaman aşımı (120s)");
}

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function errorResponse(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
