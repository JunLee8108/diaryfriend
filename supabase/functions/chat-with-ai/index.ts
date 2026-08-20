// supabase/functions/chat-with-ai/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};

serve(async (req) => {
  // CORS 처리
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { character, conversation, language } = await req.json();

    // 캐릭터 정보 로깅 (디버깅용)
    console.log("📌 Character Info:", {
      name: character.name,
      personality: character.personality,
      description: character.description,
      prompt_description: character.prompt_description
    });

    // 간결한 시스템 프롬프트 (prompt_description에 이미 personality가 녹아있음)
    const systemPrompt = `${character.prompt_description || character.description || ""}

You are having a casual conversation with someone about their day.

- Ask thoughtful follow-up questions to understand their feelings and experiences
- Show genuine interest and empathy
- Keep responses concise but warm (2-3 sentences max)
- Avoid sexual, violent, or explicitly harmful content. If such topics arise, gently guide toward emotional healing or reflection.

Language: ${language === "Korean" ? "Korean" : "English"}`;

    console.log("📝 System Prompt:", systemPrompt);

    // OpenAI Responses API 호출
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`
      },
      body: JSON.stringify({
        model: "gpt-5.6-luna",
        instructions: systemPrompt,
        input: conversation,
        reasoning: { effort: "none" },
        text: { verbosity: "low" }
      })
    });

    if (!response.ok) {
      const error = await response.text();
      console.error("❌ OpenAI API error:", error);
      throw new Error("Failed to generate AI response");
    }

    const data = await response.json();

    // 응답 파싱: output_text 우선, 실패 시 output 배열 탐색
    let aiResponse: string | undefined = data.output_text;

    if (!aiResponse) {
      const messageItem = data.output?.find((item: any) => item.type === "message");
      aiResponse = messageItem?.content?.find(
        (c: any) => c.type === "output_text"
      )?.text;
    }

    // 빈 응답 방어 (reasoning "none" 버그 대응 로깅 + 언어별 fallback)
    if (!aiResponse || aiResponse.trim() === "") {
      console.error("⚠️ Empty response detected:", {
        status: data.status,
        incomplete_details: data.incomplete_details,
        usage: data.usage
      });
      aiResponse = language === "Korean"
        ? "듣고 있어요. 오늘 있었던 일을 더 말해줄래요?"
        : "I'm here to listen. Tell me more about your day.";
    }

    console.log("✅ AI Response:", aiResponse.substring(0, 100) + "...");
    console.log("📊 Usage:", data.usage);

    return new Response(
      JSON.stringify({ success: true, response: aiResponse }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("❌ Chat AI error:", error);
    return new Response(
      JSON.stringify({ error: error.message, success: false }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" }
      }
    );
  }
});
