# syntax=docker/dockerfile:1

# =========================================================================
# Best Practices Hint: .dockerignore
# =========================================================================
# For the best build performance and to avoid accidentally leaking secrets,
# create a .dockerignore file in the same directory as this Dockerfile.
#
# A good .dockerignore file for a Go project would include:
#
# .git
# .vscode
# .idea
# *.md
# Dockerfile
# .dockerignore
# /vendor/
#
# =========================================================================

# =========================================================================
# Stage 1: Builder
# =========================================================================
# This stage compiles the Go application into a static binary.
# Using a specific version with a SHA256 digest ensures reproducible builds.
# Alpine is used for its small size.
FROM golang:1.21.6-alpine3.18@sha256:d82f25433a598c4779954e7d228dd946122557e05a8d115e8b06659c037807a5 AS builder

# Set the working directory inside the container.
WORKDIR /src

# Copy module dependency files.
# This is done as a separate step to leverage Docker's layer caching.
# The 'go mod download' command will only be re-run if go.mod or go.sum change.
COPY go.mod go.sum ./

# Use BuildKit's cache mount to speed up dependency downloads on subsequent builds.
RUN --mount=type=cache,target=/go/pkg/mod go mod download

# Copy the rest of the application's source code.
COPY . .

# Build the application into a single, statically-linked binary.
# - CGO_ENABLED=0: Disables CGO to create a static binary without any C dependencies.
# - -trimpath: Removes all file system paths from the resulting executable.
# - -ldflags="-w -s": Strips debugging information, reducing the binary size.
# Using a BuildKit cache mount for the Go build cache speeds up compilation.
RUN --mount=type=cache,target=/root/.cache/go-build CGO_ENABLED=0 go build -trimpath -ldflags="-w -s" -o /app/server .

# =========================================================================
# Stage 2: Final Production Image
# =========================================================================
# This stage creates the final, minimal production image.
# We use a distroless static image for a minimal attack surface; it contains
# only our application and its direct runtime dependencies (nothing else).
# Pinning the digest ensures we get the exact same base image every time.
FROM gcr.io/distroless/static-debian12@sha256:e36513e9834d8d1e07b489d41d4cb439626b911ac21b920b368739d48b1c416e

# OCI labels for metadata, see https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="My Go Application"
LABEL org.opencontainers.image.description="A production-ready Go application container."
# Remember to change the source URL to your repository.
LABEL org.opencontainers.image.source="https://github.com/your-repo/your-project"
LABEL org.opencontainers.image.licenses="MIT"

# Copy the compiled binary from the builder stage.
COPY --from=builder /app/server /app/server

# Expose the port the application listens on.
# This is documentation for the user and tooling. It does not publish the port.
EXPOSE 8080

# HEALTHCHECK instruction to check if the application is healthy.
# IMPORTANT: The 'distroless/static' image has NO shell or other tools (like curl/wget).
# Your application binary MUST implement its own health check logic.
# The command below assumes your server binary will exit with status 0 if healthy
# when called with a 'healthz' argument, and a non-zero status otherwise.
# Example Go implementation:
# if len(os.Args) > 1 && os.Args[1] == "healthz" {
#   // your health check logic
#   os.Exit(0)
# }
HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/app/server", "healthz"]

# Run the application as a non-root user for security.
# The 'nonroot' user (UID 65532) is provided by the distroless base image.
USER 65532:65532

# Set the entrypoint for the container.
# This is the command that will be executed when the container starts.
ENTRYPOINT ["/app/server"]