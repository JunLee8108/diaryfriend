// supabase/functions/generate-diary-from-chat/index.ts
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
    const { character, conversation, language } = await req.json();
    // Supabase 클라이언트 생성
    const supabaseClient = createClient(Deno.env.get("SUPABASE_URL") ?? "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "");
    // 대화 내용을 텍스트로 변환 (빈 메시지 필터링)
    const conversationText = conversation.filter((msg)=>msg.content?.trim()).map((msg)=>{
      const speaker = msg.role === "user" ? "나" : character.name;
      return `${speaker}: ${msg.content}`;
    }).join("\n");
    // 통합 프롬프트 - 일기, mood, hashtags를 한 번에 생성
    const systemPrompt = language === "Korean" ? `당신은 사용자의 대화 내용을 바탕으로 감성적이고 진솔한 1인칭 일기와 감정 분석, 해시태그를 생성하는 전문가입니다.

## 작업 내용
1. 1인칭 시점의 일기 작성
2. 대화에서 드러난 감정 분석
3. 핵심 키워드로 해시태그 생성

## 일기 작성 원칙
- 관점: 반드시 사용자의 1인칭 시점 ("나는", "내가")
- 근거: 오직 제공된 대화 내용에만 기반
- 톤: 진솔하고 내면적인 독백, 일기장에 손으로 쓰는 것처럼 자연스럽게
- HTML 포맷: <p> 태그로 문단 구분
- 분량: 100-200자
- 과도한 미화나 거짓 긍정 피하기
- ${character.name}을 직접 언급하지 말 것

## 감정 분석 원칙
- 대화 전체의 감정 톤을 종합적으로 판단
- happy: 긍정적, 즐거운, 희망적인 내용이 주를 이룸
- sad: 우울, 슬픔, 힘듦이 주를 이룸
- neutral: 특별한 감정 없이 담담하거나 감정이 혼재

## 필수 포함 요소
- 대화에서 나눈 핵심 주제나 내용 (구체적인 사건이나 고민)
- 그 순간 느꼈던 솔직한 감정 (단순한 감정 단어가 아닌 구체적 묘사)
- 대화를 통해 얻은 개인적 깨달음이나 새로운 시각
- 하루를 마무리하는 짧은 소감이나 다짐

## 작성 스타일
- 감정 표현을 구체적으로: 예)"기뻤다" → "마음이 한결 가벼워졌다"
- 짧은 문장과 긴 문장을 적절히 섞어서 문장 길이를 다양하게
- 대화 내용을 그대로 옮기지 말고 감정과 생각으로 재구성

## 해시태그 생성 원칙
- 대화의 핵심 주제와 감정을 나타내는 단어 선택
- 2-3개 생성 (AI일기 태그 제외)
- 한국어 우선, 필요시 영어 혼용
- 구체적이고 의미 있는 단어 사용
- # 기호 없이 단어만 반환

## 응답 필드 설명
- diary: HTML 형식의 일기 내용
- mood: "happy" 또는 "neutral" 또는 "sad"
- mood_confidence: 0.7~1.0 사이의 숫자
- hashtags: 태그 문자열 배열
- analysis: 감정 판단 근거 (디버깅용)` : `You are an expert at creating heartfelt diary entries, analyzing emotions, and generating hashtags from conversations.

## Tasks
1. Write a first-person diary entry
2. Analyze emotions from the conversation
3. Generate hashtags from key topics

## Diary Writing Principles
- Perspective: First person from user's viewpoint ("I", "my")
- Evidence: Based ONLY on provided conversation
- Tone: Personal and reflective
- HTML Format: use <p> tags
- Length: 100-200 words
- Don't mention ${character.name} directly

## Emotion Analysis Principles
- Judge overall emotional tone comprehensively
- happy: Positive, joyful, hopeful content dominates
- sad: Depression, sadness, difficulty dominates
- neutral: Calm or mixed emotions

## Hashtag Generation Principles
- Choose words representing core topics and emotions
- Generate 2-3 tags (exclude "AIDiary" tag)
- Prioritize English, mix languages if needed
- Use specific, meaningful words
- Return words only, without the # symbol

## Response Field Guide
- diary: HTML formatted diary content
- mood: "happy" or "neutral" or "sad"
- mood_confidence: number between 0.7-1.0
- hashtags: array of tag strings
- analysis: Reasoning for emotion judgment (for debugging)`;
    const userPrompt = language === "Korean" ? `다음 대화를 분석하여 응답해주세요:

대화 내용:
${conversationText}

1. 위 대화를 바탕으로 1인칭 일기 작성
2. 전체적인 감정(mood) 판단
3. 핵심 해시태그 2-3개 생성` : `Analyze this conversation and respond:

Conversation:
${conversationText}

1. Write a first-person diary based on this conversation
2. Determine overall mood
3. Generate 2-3 key hashtags`;
    // OpenAI Responses API 호출 (Structured Outputs로 스키마 강제)
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${Deno.env.get("OPENAI_API_KEY")}`
      },
      body: JSON.stringify({
        model: "gpt-5.6-luna",
        instructions: systemPrompt,
        input: userPrompt,
        reasoning: {
          effort: "low"
        },
        max_output_tokens: 2000,
        text: {
          format: {
            type: "json_schema",
            name: "diary_result",
            strict: true,
            schema: {
              type: "object",
              properties: {
                diary: {
                  type: "string"
                },
                mood: {
                  type: "string",
                  enum: [
                    "happy",
                    "neutral",
                    "sad"
                  ]
                },
                mood_confidence: {
                  type: "number"
                },
                hashtags: {
                  type: "array",
                  items: {
                    type: "string"
                  }
                },
                analysis: {
                  type: "string"
                }
              },
              required: [
                "diary",
                "mood",
                "mood_confidence",
                "hashtags",
                "analysis"
              ],
              additionalProperties: false
            }
          }
        }
      })
    });
    if (!response.ok) {
      const error = await response.text();
      console.error("OpenAI API error:", error);
      throw new Error("Failed to generate diary with analysis");
    }
    const data = await response.json();
    // 응답 파싱: output_text 우선, 실패 시 output 배열 탐색
    let rawText = data.output_text;
    if (!rawText) {
      const messageItem = data.output?.find((item)=>item.type === "message");
      rawText = messageItem?.content?.find((c)=>c.type === "output_text")?.text;
    }
    let aiResponse;
    try {
      // JSON 파싱 (Structured Outputs가 스키마를 보장하지만 안전망 유지)
      aiResponse = JSON.parse(rawText || "{}");
    } catch (parseError) {
      console.error("JSON parsing error:", parseError, {
        status: data.status,
        incomplete_details: data.incomplete_details
      });
      // 파싱 실패 시 기본값으로 폴백
      aiResponse = {
        diary: rawText || "",
        mood: "neutral",
        mood_confidence: 0.5,
        hashtags: [
          "일기",
          "오늘"
        ],
        analysis: "Failed to parse AI response"
      };
    }
    // 응답 검증 및 보정
    const validatedResponse = {
      diary: aiResponse.diary || `<p>오늘의 일기</p>`,
      mood: [
        "happy",
        "neutral",
        "sad"
      ].includes(aiResponse.mood) ? aiResponse.mood : "neutral",
      mood_confidence: typeof aiResponse.mood_confidence === 'number' ? Math.min(1, Math.max(0, aiResponse.mood_confidence)) : 0.7,
      hashtags: Array.isArray(aiResponse.hashtags) && aiResponse.hashtags.length > 0 ? aiResponse.hashtags.map((tag)=>String(tag).replace(/^#+/, "").trim()).filter(Boolean).slice(0, 5) // # 제거 + 최대 5개로 제한
       : [
        language === "Korean" ? "일상" : "Daily"
      ],
      analysis: aiResponse.analysis || ""
    };
    // 기본 HTML 포맷팅 (필요한 경우)
    if (!validatedResponse.diary.includes("<p>")) {
      const lines = validatedResponse.diary.split('\n');
      const dateLine = lines[0];
      const contentLines = lines.slice(1).join('\n').trim();
      validatedResponse.diary = `${dateLine}\n<p>${contentLines.replace(/\n\n/g, "</p><p>").replace(/\n/g, "<br>")}</p>`;
    }
    return new Response(JSON.stringify({
      success: true,
      diary: validatedResponse.diary,
      mood: validatedResponse.mood,
      mood_confidence: validatedResponse.mood_confidence,
      hashtags: validatedResponse.hashtags,
      metadata: {
        conversation_length: conversation.length,
        character_name: character.name,
        language: language,
        generated_at: new Date().toISOString(),
        analysis: validatedResponse.analysis
      }
    }), {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  } catch (error) {
    console.error("Generate diary error:", error);
    // 에러 발생 시에도 기본 응답 제공
    return new Response(JSON.stringify({
      error: error.message,
      success: false,
      // 폴백 데이터
      diary: "",
      mood: "neutral",
      hashtags: [],
      mood_confidence: 0
    }), {
      status: 400,
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json"
      }
    });
  }
});
