/**
 * Prova — ai-stylist Edge Function
 *
 * Calls Google Gemini 1.5 Flash (FREE tier) with:
 * - User's wardrobe as structured context
 * - Conversation history
 * - User's message
 *
 * Returns structured JSON for the Flutter UI to render as:
 * - Outfit suggestion cards (with item IDs mapped to wardrobe)
 * - Style tips list
 * - Outfit rating
 * - Follow-up question chips
 *
 * Free tier: 15 RPM, 1M tokens/day — sufficient for MVP.
 * Get key: aistudio.google.com/app/apikey
 */

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY")!;
const GEMINI_MODEL = "gemini-1.5-flash-latest";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}`;

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Auth check
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return errorResponse("Yetkisiz", 401);

    const userClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) return errorResponse("Kullanıcı doğrulanamadı", 401);

    // Parse body
    const {
      message,
      wardrobe = [],
      history = [],
      session_id,
    } = await req.json();

    if (!message?.trim()) return errorResponse("Mesaj boş olamaz", 400);

    // Build structured Gemini prompt
    const systemPrompt = buildSystemPrompt(wardrobe);
    const contents = buildContents(history, message);

    // Call Gemini
    const geminiResponse = await fetch(GEMINI_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        system_instruction: { parts: [{ text: systemPrompt }] },
        contents,
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1500,
          responseMimeType: "application/json",
        },
        safetySettings: [
          { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
          { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK_MEDIUM_AND_ABOVE" },
        ],
      }),
    });

    if (!geminiResponse.ok) {
      const errText = await geminiResponse.text();
      console.error("Gemini error:", errText);
      throw new Error(`Gemini API hatası: ${geminiResponse.status}`);
    }

    const geminiData = await geminiResponse.json();
    const rawText =
      geminiData.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";

    // Parse and validate the structured response
    let structured: Record<string, unknown>;
    try {
      structured = JSON.parse(rawText);
    } catch {
      // Gemini sometimes wraps in markdown code blocks — strip them
      const cleaned = rawText.replace(/```json\n?|\n?```/g, "").trim();
      try {
        structured = JSON.parse(cleaned);
      } catch {
        structured = { message: rawText, response_type: "general" };
      }
    }

    // Ensure required fields
    const response = {
      response_type: structured.response_type ?? "general",
      message: structured.message ?? rawText,
      outfit_suggestions: structured.outfit_suggestions ?? [],
      style_tips: structured.style_tips ?? [],
      missing_items: structured.missing_items ?? [],
      rating: structured.rating ?? null,
      follow_up_questions: structured.follow_up_questions ?? [],
    };

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("ai-stylist error:", err);
    return errorResponse(`Stilist şu an yanıt veremiyor: ${err.message}`, 500);
  }
});

/**
 * Build the system prompt with wardrobe context.
 * Wardrobe items are injected as a structured list.
 */
function buildSystemPrompt(wardrobe: Array<Record<string, unknown>>): string {
  const wardrobeText =
    wardrobe.length === 0
      ? "Kullanıcının henüz gardırobunda kıyafet yok."
      : wardrobe
          .map(
            (item) =>
              `- ID: ${item.id} | ${item.category || "?"} | ${item.color || "?"} renk | ${item.name || "isimsiz"} | Marka: ${item.brand || "belirtilmemiş"} | Mevsim: ${item.season || "her mevsim"} | Ortam: ${item.occasion || "her ortam"}`
          )
          .join("\n");

  return `Sen Prova uygulamasının kişisel AI stilistisin. Türkçe konuşursun.
Kullanıcının gardırobunu bilerek, onun için kombine özel ve uygulanabilir stil önerileri yaparsın.

KULLANICININ GARDIROBU:
${wardrobeText}

GÖREVIN:
- Sadece gardırobundaki kıyafetleri kullanarak kombinler öner (item ID'leri kullan)
- Eksik parçaları belirt ama önce elindekilerle ne yapabileceğini göster
- Türk kültürüne uygun, pratik ve şık öneriler yap
- Kombini neden önerdiğini kısaca açıkla
- Genel moda tavsiyesi değil, KİŞİSEL gardıroba dayalı tavsiye ver

YANIT FORMATI (SADECE GEÇERLİ JSON DÖN):
{
  "response_type": "outfit_suggestion" | "style_advice" | "outfit_rating" | "wardrobe_analysis" | "general",
  "message": "Kullanıcıya gösterilecek ana mesaj (2-3 cümle, sıcak ve kişisel ton)",
  "outfit_suggestions": [
    {
      "name": "Kombin adı (ör: 'Casual Pazartesi')",
      "item_ids": ["gardırop item ID'leri buraya"],
      "missing_items": ["Eksik parçalar varsa (ör: 'beyaz sneaker')"],
      "reasoning": "Bu kombini neden öneriyorum (1-2 cümle)",
      "occasion": "casual | work | evening | formal | sport",
      "confidence": 0.0-1.0
    }
  ],
  "style_tips": ["İpucu 1", "İpucu 2"],
  "missing_items": ["Gardırobu tamamlamak için önerilen genel parçalar"],
  "rating": null | {
    "score": 1-10,
    "summary": "Değerlendirme özeti",
    "positives": ["Güçlü yön 1"],
    "improvements": ["Geliştirilecek yön 1"]
  },
  "follow_up_questions": ["Sonraki öneri sorusu 1 (kısa, ör: 'Daha resmi bir versiyon ister misin?')"]
}

KURALLAR:
- Outfit suggestions dizisi çoğunlukla 1-3 kombin içermeli
- Gardırop boşsa genel tavsiye ver, item_ids boş liste
- Rating sadece kullanıcı bir kombini değerlendirmemi istediğinde doldur
- Follow-up max 2 soru
- Yanıt sıcak, özgüvenli, bir arkadaş gibi — resmi veya kuru değil`;
}

/**
 * Format conversation history for Gemini's multi-turn format.
 */
function buildContents(
  history: Array<{ role: string; content: string }>,
  newMessage: string
) {
  const contents = history
    .filter((h) => h.content?.trim())
    .map((h) => ({
      role: h.role === "assistant" ? "model" : "user",
      parts: [{ text: h.content }],
    }));

  contents.push({
    role: "user",
    parts: [{ text: newMessage }],
  });

  return contents;
}

function errorResponse(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
