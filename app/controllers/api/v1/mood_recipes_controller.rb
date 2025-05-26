class Api::V1::MoodRecipesController < ApplicationController
  def create
    mood = params.require(:mood)

    # 材料の分量と何人前という情報、作成にかかる時間を追加したい
    prompt = <<~PROMPT
      あなたはプロの料理研究家です。
      「#{mood}」気分の人におすすめの晩御飯のレシピを３品、
      以下の **JSON** 形式で日本語出力して下さい。
      欲しい情報
      料理名
      材料
      分量（材料名は入れないでください）
      作成方法
      何人前
      料理時間
      [
        {
          "title": "...",
          "ingredients": ["..., ..."],
          "gram": "...",
          "steps": ["...", "..."],
          "servings": "...",
          "cook_time": "..."
        }
      ]
      PROMPT

      ai = ::OpenAI::Client.new(access_token: ENV.fetch("OPENAI_API_KEY"))
      raw = ai.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [ { role: "user", content: prompt } ],
          temperature: 0.8
        }
      ).dig("choices", 0, "message", "content")

      # ```json```がつく場合に備えトリム
      json_text = raw.gsub(/```json|```/, "").strip
      recipes = JSON.parse(json_text)

      render json: { recipes: recipes }, status: :ok
    rescue JSON::ParserError => e
      render json: { error: "AIからのJSON解析に失敗しました" }, status: :unprocessable_entity
  end
end
