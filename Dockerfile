# --- Stage 1: Build Stage ---
# Use a specific version of the Python image. Alpine-based images are smaller.
# Naming the stage 'builder' makes it clear and easy to reference in the next stage.
FROM python:3.11-alpine3.19 AS builder

# Set the working directory in the container.
WORKDIR /app

# --- Best Practice: .dockerignore ---
# To prevent copying unnecessary files (like .git, local env files, or the Dockerfile itself)
# into the build context and later into the image, create a .dockerignore file.
# Example .dockerignore content:
#
# Dockerfile
# .dockerignore
# .git/
# .venv/
# *.pyc
# __pycache__/

# Copy the dependency file first to leverage Docker's layer caching.
# The layer for installing dependencies will only be rebuilt if requirements.txt changes.
COPY requirements.txt .

# Create Python wheels for all dependencies.
# Using 'pip wheel' pre-compiles dependencies, which means we don't need build tools
# (like C compilers) in the final, minimal runtime image.
# --no-cache-dir reduces layer size.
RUN pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# Copy the rest of the application source code.
# This is done after dependency installation to ensure that code changes
# do not invalidate the dependency cache layer.
COPY . .


# --- Stage 2: Final/Runtime Stage ---
# Use a minimal, secure base image. Pinning the version digest is the most secure way,
# but a specific version tag like 3.19.1 is also a strong practice for reproducibility.
FROM alpine:3.19.1

# --- OCI Labels ---
# Add metadata to the image using OCI labels to improve discoverability,
# automation, and security scanning.
# For more info: https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.authors="you@example.com"
LABEL org.opencontainers.image.source="https://github.com/your-repo/your-project"
LABEL org.opencontainers.image.title="My Python Application"
LABEL org.opencontainers.image.description="A production-ready Python application."
LABEL org.opencontainers.image.version="1.0.0"

# --- Security: Non-Root User ---
# Create a dedicated group and user to run the application.
# Running as a non-root user is a critical security best practice to limit
# the potential impact of a container compromise.
# We use -S for a system user/group and specify a static UID/GID for consistency.
RUN addgroup -S -g 1001 appgroup && \
    adduser -S -u 1001 -G appgroup appuser

# Install only the necessary runtime packages.
# 'python3' is the interpreter, and 'curl' is for the HEALTHCHECK.
# Using --no-cache prevents storing the package index, reducing the final image size.
# Note: The Python version here is determined by the Alpine version. It should be
# compatible with the one used in the builder stage (e.g., 3.11.x).
RUN apk add --no-cache python3 py3-pip curl

# Set the working directory for the final image.
WORKDIR /app

# Copy the pre-built wheels and the requirements file from the builder stage.
COPY --from=builder /wheels /wheels
COPY --from=builder /app/requirements.txt .

# Install the Python dependencies from the local wheel files.
# This is fast, doesn't require network access, and avoids needing build tools.
# We then clean up the wheels and requirements file to keep the image lean.
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt && \
    rm -rf /wheels requirements.txt

# Copy the application source code from the builder stage.
COPY --from=builder /app .

# Set ownership of the application directory to the non-root user.
# This ensures the application has the correct permissions to run.
RUN chown -R appuser:appgroup /app

# Switch to the non-root user for executing subsequent commands.
USER appuser

# --- Clarity & Operations: EXPOSE ---
# Expose the port the application listens on.
# This serves as documentation for the user and can be used by orchestration tools.
# Replace 8000 with your application's actual port.
EXPOSE 8000

# --- Health & Reliability: HEALTHCHECK ---
# Add a healthcheck to let the container runtime know if the application is still working.
# This command curls a health endpoint. Adjust the path and port as needed.
# If your app doesn't have an HTTP endpoint, consider a different check (e.g., a custom script).
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8000/health || exit 1

# Define the command to run the application.
# Using the exec form (JSON array) is preferred as it avoids shell processing and
# allows signals (like SIGTERM for graceful shutdown) to be passed directly to the process.
CMD ["python3", "app.py"]