# Build stage
FROM elixir:1.16-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git nodejs npm

# Set working directory
WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set environment variables
ENV MIX_ENV=prod

# Copy over mix files
COPY mix.exs mix.lock ./
COPY config config

# Get dependencies
RUN mix deps.get --only prod

# Copy over assets
COPY assets assets
COPY priv priv

# Copy over all application code
COPY lib lib

# Compile the application
RUN mix compile

# Build the release
RUN mix phx.digest && \
    mix release

# Runtime stage
FROM alpine:3.18 AS app

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs

# Set working directory
WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/shader_generator ./

# Set environment variables
ENV PORT=4000 \
    LANG=C.UTF-8

# Expose the port
EXPOSE 4000

# Set the entrypoint
ENTRYPOINT ["/app/bin/shader_generator"]
CMD ["start"]
