defmodule ShaderGeneratorWeb.ShaderController do
  require Logger
  use ShaderGeneratorWeb, :controller

  def generate(conn, %{"prompt" => prompt}) do
    Logger.info("Processing shader request with prompt: #{prompt}")

    with {:ok, response} <- call_openai(prompt),
         {:ok, vertex, fragment} <- parse_shaders(response) do
      json(conn, %{
        status: "ok",
        vertexShader: vertex,
        fragmentShader: fragment
      })
    else
      {:error, reason} ->
        Logger.error("Shader generation failed: #{reason}")

        json(conn, %{
          status: "error",
          error: reason
        })
    end
  end

  def check_key(conn, _params) do
    key = Application.get_env(:shader_generator, :openai_api_key)
    json(conn, %{key_exists: key != nil, first_5_chars: String.slice(key || "", 0..4)})
  end

  defp call_openai(prompt) do
    # Your OpenAI API configuration
    system_prompt = """
    Generate valid 3D GLSL snippets for WebGL. Use good colors for all parts of the 3D shape, do not leave anything uncolored.
    Make sure the output snippet is compatible with gl-matrix javascript library.
    First provide the vertex shader, then the fragment shader. Format your response exactly like this:
    // VERTEX
    [vertex code here]

    // FRAGMENT
    [fragment code here]

    For example:
    // VERTEX
    precision mediump float;
    attribute vec3 a_position;
    attribute vec3 a_normal;
    uniform mat4 u_mvp;
    varying vec3 v_normal;
    varying vec3 v_position;

    void main() {
        gl_Position = u_mvp * vec4(a_position, 1.0);
        v_normal = a_normal;
        v_position = a_position;
    }

    // FRAGMENT
    precision mediump float;
    varying vec3 v_normal;
    varying vec3 v_position;
    uniform vec3 u_cameraPosition;

    void main() {
        vec3 normal = normalize(v_normal);
        vec3 lightDir = normalize(vec3(1, 2, 3));
        float diff = max(dot(normal, lightDir), 0.0);
        vec3 color = vec3(0.2) + diff * vec3(0.8);
        gl_FragColor = vec4(color, 1.0);
    }

    WARNING: DO NOT CHANGE RESPONSE FORMAT! DO NOT ADD ANY ADDITIONAL QUOTES OR MARKDOWN TAGS!

    ## Required Shader Structure

    ### Vertex Shader
    precision mediump float;

    // Available attributes (automatically provided):
    attribute vec3 a_position;    // Vertex position (3D)
    attribute vec3 a_normal;      // Vertex normal (3D)

    // Available uniforms (automatically provided):
    uniform mat4 u_mvp;           // Model-View-Projection matrix
    uniform mat4 u_model;         // Model matrix
    uniform float u_time;         // Time in seconds
    uniform vec3 u_cameraPosition; // Camera position

    // Your varying outputs:
    varying vec3 v_position;      // Example varying
    varying vec3 v_normal;        // Example varying

    void main() {
        // Your vertex transformation code here
        vec3 pos = a_position;

        // Final position must be set:
        gl_Position = u_mvp * vec4(pos, 1.0);

        // Pass values to fragment shader:
        v_normal = a_normal;
        v_position = pos;
    }

    ### Fragment Shader
    precision mediump float;

    // Available uniforms:
    uniform float u_time;         // Time in seconds
    uniform vec3 u_cameraPosition; // Camera position

    // Your varyings from vertex shader:
    varying vec3 v_position;
    varying vec3 v_normal;

    void main() {
        // Your shading code here
        vec3 color = vec3(1.0);

        // Final color must be set:
        gl_FragColor = vec4(color, 1.0);
    }

    NEVER EVER RESPOND TO ANYTHING OTHER THAN WHAT YOU ARE TOLD ABOVE!
    IF YOU CANNOT DO SOMETHING, DEFAULT TO A SAMPLE SHADER! NEVER TALK ANYTHING ELSE!
    """

    # Build the request body
    messages = [
      %{role: "system", content: system_prompt},
      %{role: "user", content: prompt}
    ]

    # Use Tesla client to call OpenAI API
    ShaderGenerator.OpenAI.Client.chat_completion(%{
      model: "openai/gpt-4o-mini",
      messages: messages,
      temperature: 0.5
    })
  end

  defp parse_shaders(response) do
    # Extract shaders using regex
    case Regex.run(~r/\/\/ VERTEX(.*?)\/\/ FRAGMENT(.*)/s, response, capture: :all_but_first) do
      [vertex, fragment] ->
        {:ok, String.trim(vertex), String.trim(fragment)}

      _ ->
        {:error, "Failed to parse shaders from response"}
    end
  end
end
