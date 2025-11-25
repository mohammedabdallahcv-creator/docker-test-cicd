#
# --- Stage 1: Build ---
#
# Use a specific version of Node.js for reproducible builds.
# The 'alpine' variant is used for its small size.
# We name this stage 'builder' to be able to refer to it in the next stage.
#
FROM node:18.19.1-alpine AS builder

# Set the working directory in the container.
WORKDIR /app

# IMPORTANT: Create a .dockerignore file in your project root to exclude
# files and directories that are not needed in the image, such as:
#
# node_modules
# .git
# .env
# Dockerfile
#
# This improves build times and security.

# Copy package.json and package-lock.json (or yarn.lock, etc.).
# This is done in a separate step to leverage Docker's layer caching.
# The 'npm ci' step will only be re-run if these files change.
COPY package*.json ./

# Use 'npm ci' (clean install) for deterministic and faster installs.
# It strictly uses the package-lock.json, which is ideal for production builds.
# It installs all dependencies, including devDependencies, which might be needed
# for building or testing the application in this stage.
RUN npm ci

# Copy the rest of the application source code into the container.
# This is done after installing dependencies, as source code changes more frequently.
COPY . .

# If your application needs a build step (e.g., transpiling TypeScript, bundling assets),
# it would go here. For example:
# RUN npm run build

#
# --- Stage 2: Production ---
#
# Use the same small and secure Node.js Alpine base image.
# This final image will only contain the files needed to run the application,
# resulting in a smaller attack surface and faster deployment.
#
FROM node:18.19.1-alpine

# Set Open Container Initiative (OCI) labels for image metadata.
# This helps with image organization and provides useful information.
# Learn more at: https://github.com/opencontainers/image-spec/blob/main/annotations.md
LABEL org.opencontainers.image.title="production-node-app" \
      org.opencontainers.image.description="A production-ready Node.js application." \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://github.com/your-org/your-repo" \
      org.opencontainers.image.authors="Your Name <you@example.com>"

# Set the environment to 'production'.
# This is a standard convention that many libraries and frameworks use to
# enable production-specific optimizations (e.g., caching, logging).
ENV NODE_ENV=production

# Create a dedicated, non-root user and group for the application.
# Using a static UID/GID is a good practice for predictable permissions.
# Running as a non-root user is a critical security best practice to
# limit the blast radius in case of a container compromise.
RUN addgroup -S -g 1001 appgroup && \
    adduser -S -u 1001 -G appgroup appuser

# Install curl, which is required for the HEALTHCHECK.
# Using --no-cache avoids storing the package index, keeping the image layer small.
RUN apk add --no-cache curl

# Set the working directory.
WORKDIR /app

# Copy package files from the 'builder' stage.
COPY --from=builder /app/package*.json ./

# Install *only* the production dependencies.
# The --omit=dev flag ensures devDependencies are not installed,
# resulting in a smaller and more secure final image.
RUN npm ci --omit=dev

# Copy the application code (or build output) from the 'builder' stage.
# The --chown flag sets the ownership to our non-root user, so we don't
# have to run 'chown' in a separate, less efficient layer.
COPY --from=builder --chown=appuser:appgroup /app/ .

# Switch to the non-root user for all subsequent commands.
USER appuser

# Expose the port the application listens on.
# This is documentation for the user/operator; it does not publish the port.
EXPOSE 3000

# Add a HEALTHCHECK instruction.
# Docker uses this to determine if the container is healthy.
# It attempts to curl the root path every 30 seconds. Adjust the CMD as needed
# for your application's health endpoint (e.g., /healthz).
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD [ "curl", "-f", "http://localhost:3000/" ]

# Define the command to run the application.
# Use the array syntax ('exec' form) to avoid shell wrapping. This allows signals
# like SIGTERM (from 'docker stop') to be passed directly to the Node.js process,
# enabling graceful shutdowns.
CMD ["npm", "start"]