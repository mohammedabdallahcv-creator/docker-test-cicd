# =================================================================================================
# --- Best practices and explanations are included in the comments of this Dockerfile. ---
#
# A .dockerignore file is crucial for keeping the build context small and avoiding
# leaking secrets. Create a .dockerignore file in the same directory with at least:
#
# .git
# .gitignore
# .dockerignore
# node_modules
# npm-debug.log
# Dockerfile
# README.md
# *.env
#
# =================================================================================================


# =================================================================================================
# BUILDER STAGE
# Use a specific version of Node.js for reproducible builds.
# 'alpine' images are smaller, which leads to faster downloads and smaller image sizes.
# Naming the stage 'builder' for clarity.
# =================================================================================================
FROM node:18.20.2-alpine3.19 AS builder

# Set the working directory in the container.
WORKDIR /app

# Copy package.json and package-lock.json (or yarn.lock, etc.)
# This is done in a separate layer to leverage Docker's layer caching.
# This layer will only be invalidated if these package files change.
COPY package*.json ./

# Install production dependencies using 'npm ci'.
# 'npm ci' is faster, more reliable, and strictly uses the package-lock.json,
# which is ideal for production builds.
# The --omit=dev flag ensures that development dependencies are not installed.
RUN npm ci --omit=dev

# Copy the rest of the application source code into the container.
# The .dockerignore file will prevent unnecessary files from being copied.
COPY . .

# If your application has a build step (e.g., transpiling TypeScript), it would go here.
# For example: RUN npm run build


# =================================================================================================
# PRODUCTION STAGE
# Start a new, clean stage from the same base image to keep the final image minimal.
# This ensures that no build tools or development dependencies end up in the production image.
# =================================================================================================
FROM node:18.20.2-alpine3.19

# Add Open Container Initiative (OCI) labels for image metadata.
# This is useful for image scanners and management tools.
# See https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.authors="your-name@example.com"
LABEL org.opencontainers.image.source="https://github.com/your-repo/your-project"
LABEL org.opencontainers.image.description="Production image for the Node.js application."
LABEL org.opencontainers.image.licenses="MIT"

# Set the working directory.
WORKDIR /app

# Create a dedicated, non-root user and group for the application.
# Running as a non-root user is a critical security best practice to mitigate
# potential container breakout vulnerabilities.
RUN addgroup -S --gid 1001 appgroup && \
    adduser -S --uid 1001 appuser -G appgroup

# Copy dependencies and source code from the 'builder' stage.
# The --chown flag sets the ownership of the copied files to the new non-root user.
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app .

# Switch to the non-root user. Subsequent commands will be run as this user.
USER appuser

# Expose the port that the application listens on.
# This is for documentation and to allow easy mapping from the host.
EXPOSE 3000

# Add a healthcheck to your container.
# Docker will use this to check if your application is still alive and healthy.
# The node:alpine image includes 'wget', which is used here.
# Customize the endpoint (e.g., '/healthz') for your application's health check.
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/ || exit 1

# Define the command to run the application.
# Use 'node' directly instead of 'npm start' to ensure that your application
# is PID 1. This allows it to receive signals (like SIGTERM) from the Docker daemon,
# enabling graceful shutdowns.
# Ensure your application's code handles SIGINT/SIGTERM for a clean exit.
# Replace 'server.js' with the actual entrypoint of your application.
CMD [ "node", "server.js" ]