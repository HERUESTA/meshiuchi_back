class Api::V1::MoodRecipesController < ApplicationController
  protect_from_forgery with: :null_session
  def create
    mood = params.require(:mood)

    prompt = <<~PROMPT
      あなたはプロの料理研究家です。
      「#{mood}」気分の人におすすめの晩御飯のレシピを３品、
      以下の **JSON** 形式で日本語出力して下さい。
      [
        {
          "title": "...",
          "ingredients": ["..., ..."],
          "steps": ["...", "..."]
        }
      ]
      PROMPT

      ai = OpenAI::Client.new
      raw = ai.chat(
        parameters: {
          model: "gpt-4o-mini",
          messages: [{ role: "user", content: prompt }],
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