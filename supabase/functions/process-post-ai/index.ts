// supabase/functions/process-post-ai/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
};
serve(async (req)=>{
  // CORS 처리
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders
    });
  }
  try {
    const { postId, content, hashtags, mood, userId } = await req.json();
    // Supabase 클라이언트 생성 (SERVICE_ROLE_KEY 사용)
    const supabaseClient = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "");
    // userId가 없으면 Post에서 가져오기
    let targetUserId = userId;
    if (!targetUserId) {
      const { data: postData, error: postError } = await supabaseClient.from("Post").select("user_id").eq("id", postId).single();
      if (postError) throw postError;
      targetUserId = postData.user_id;
    }
    console.log(`Processing AI comments for user: ${targetUserId}, post: ${postId}`);
    // 1. 사용자가 팔로잉하는 캐릭터만 가져오기
    const { data: followedCharacters, error: charError } = await supabaseClient.from("Character").select(`
        *,
        User_Character!inner(
          user_id,
          is_following,
          affinity
        )
      `).eq("is_system_default", true).eq("User_Character.user_id", targetUserId).eq("User_Character.is_following", true);
    if (charError) {
      console.error("Failed to fetch followed characters:", charError);
      throw charError;
    }
    if (!followedCharacters || followedCharacters.length === 0) {
      console.log("No followed characters found");
      return new Response(JSON.stringify({
        success: true,
        message: "No followed characters to generate comments",
        commentCount: 0
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      });
    }
    // 랜덤으로 섞기
    const shuffled = followedCharacters.sort(()=>0.5 - Math.random());
    // 팔로잉 수에 따른 댓글 로직
    const followedCount = followedCharacters.length;
    if (followedCount === 0) {
      return new Response(JSON.stringify({
        success: true,
        message: "No followed characters",
        commentCount: 0
      }), {
        headers: {
          ...corsHeaders,
          "Content-Type": "application/json"
        }
      });
    }
    // 댓글: 최소 2개, 최대 3개 (팔로잉 수 제한)
    const minComments = Math.min(2, followedCount);
    const maxComments = Math.min(3, followedCount);
    const commentCount = minComments === maxComments ? minComments : Math.floor(Math.random() * (maxComments - minComments + 1)) + minComments;
    // 댓글 캐릭터 선택
    const commentCharacters = shuffled.slice(0, commentCount);
    console.log(`Following: ${followedCount}, Comments: ${commentCount}`);
    // 2. AI 댓글 생성 및 저장 (병렬 처리)
    const commentPromises = commentCharacters.map(async (char)=>{
      try {
        // OpenAI API 호출
        const aiComment = await generateAIComment(char, content, hashtags, mood);
        // 댓글 저장
        const { data: savedComment, error: commentError } = await supabaseClient.from("Comment").insert({
          post_id: postId,
          character_id: char.id,
          message: aiComment,
          like: 0
        }).select().single();
        if (commentError) {
          console.error("Failed to save comment:", commentError);
          return;
        }
        console.log(`Comment saved for character ${char.name}`);
        // 3. Affinity 업데이트 (확률적)
        const currentAffinity = char.User_Character[0]?.affinity || 0;
        let probability = 0.5; // 기본 50% 확률
        // Affinity가 높을수록 확률 감소
        if (currentAffinity > 30) probability = 0.1;
        else if (currentAffinity > 20) probability = 0.2;
        else if (currentAffinity > 10) probability = 0.3;
        const shouldIncreaseAffinity = Math.random() < probability;
        if (shouldIncreaseAffinity) {
          // User_Character 테이블 업데이트
          const { error: affinityError } = await supabaseClient.from("User_Character").update({
            affinity: currentAffinity + 1
          }).eq("user_id", targetUserId).eq("character_id", char.id);
          if (affinityError) {
            console.error("Failed to update affinity:", affinityError);
          } else {
            console.log(`Affinity increased for ${char.name}: ${currentAffinity} -> ${currentAffinity + 1}`);
          }
        }
      } catch (error) {
        console.error("Failed to generate AI comment:", error);
      }
    });
    // 모든 댓글 처리 완료 대기
    await Promise.all(commentPromises);
    // AI 처리 완료 플래그 업데이트
const { error: updateError } = await supabaseClient
  .from("Post")
  .update({ ai_processing_status: 'completed' }) // completed로 변경
  .eq("id", postId);
    return new Response(JSON.stringify({
      success: true,
      message: "AI processing started",
      commentCount: commentCharacters.length,
      userId: targetUserId
    }), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(JSON.stringify({
      error: error.message
    }), {
      status: 400,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  }
});
// OpenAI Responses API 호출 함수
async function generateAIComment(character, content, hashtags, mood) {
  const cleanContent = content.replace(/<\/?(p|div|h[1-6]|li|br)[^>]*>/gi, "\n").replace(/<[^>]*>/g, "").replace(/\n+/g, " ").replace(/\s+/g, " ").trim();
  const hashtagsText = hashtags.length > 0 ? `Hashtags: ${hashtags.map((tag)=>`#${tag}`).join(" ")}` : "";
  const moodText = mood ? `Mood: ${mood}` : "";
  const contextInfo = [
    hashtagsText,
    moodText
  ].filter(Boolean).join("\n");
  // GPT-5.6은 temperature/penalty 미지원 → 다양성은 프롬프트로 유도
  const systemPrompt = `${character.name} - ${character.prompt_description}
Stay fully immersed in this persona at all times.
Respond in the user's language.
Use short 1-2 witty sentences that preserve your unique style and divine tone.
Vary your word choice and sentence openings; never sound formulaic or repeat stock phrases.
${contextInfo ? "Consider the post's mood and hashtags to understand the emotional context." : ""}`;
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`
    },
    body: JSON.stringify({
      model: "gpt-5.6-luna",
      instructions: systemPrompt,
      input: `Content: ${cleanContent}${contextInfo ? "\n" + contextInfo : ""}`,
      reasoning: { effort: "none" },
      text: { verbosity: "low" }
    })
  });
  if (!response.ok) {
    const error = await response.text();
    console.error("OpenAI API error:", error);
    throw new Error("OpenAI API call failed");
  }
  const data = await response.json();
  // 응답 파싱: output_text 우선, 실패 시 output 배열 탐색
  let aiComment = data.output_text;
  if (!aiComment) {
    const messageItem = data.output?.find((item)=>item.type === "message");
    aiComment = messageItem?.content?.find((c)=>c.type === "output_text")?.text;
  }
  // 빈 응답 방어 (reasoning "none" 버그 대응)
  if (!aiComment || aiComment.trim() === "") {
    console.error("Empty comment response:", {
      status: data.status,
      incomplete_details: data.incomplete_details,
      usage: data.usage
    });
    return "You're doing great!";
  }
  return aiComment;
}
