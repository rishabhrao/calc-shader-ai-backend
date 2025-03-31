defmodule ShaderGenerator.OpenAI.Client do
  require Logger
  use Tesla

  plug Tesla.Middleware.BaseUrl, "https://openrouter.ai/api/v1"
  plug Tesla.Middleware.JSON

  plug Tesla.Middleware.Headers, [
    {"authorization", "Bearer #{Application.get_env(:shader_generator, :openai_api_key)}"}
  ]

  def chat_completion(params) do
    case post("/chat/completions", params) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        Logger.info("OpenAI Response: #{inspect(body, limit: 1000)}")

        case body do
          %{"choices" => [%{"message" => %{"content" => content}} | _rest]} ->
            {:ok, content}

          _ ->
            error_msg = """
            Unexpected OpenAI structure. Full response:
            #{inspect(body, limit: 200)}
            """

            {:error, error_msg}
        end

      {:ok, %Tesla.Env{status: status, body: body}} ->
        Logger.error("OpenAI Error (#{status}): #{inspect(body)}")
        {:error, body["error"]["message"] || "OpenAI API Error (status #{status})"}

      {:error, reason} ->
        Logger.error("HTTP Error: #{inspect(reason)}")
        {:error, "HTTP Error: #{inspect(reason)}"}
    end
  end
end
