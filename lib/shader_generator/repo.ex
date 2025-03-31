defmodule ShaderGenerator.Repo do
  use Ecto.Repo,
    otp_app: :shader_generator,
    adapter: Ecto.Adapters.Postgres
end
