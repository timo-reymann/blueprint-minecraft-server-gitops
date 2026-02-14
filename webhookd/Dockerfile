# License: unlicense
LABEL org.opencontainers.image.licenses="unlicense"

# =============================================================================
# Webhookd - GitOps Deployment Webhook Handler
# =============================================================================
# This container runs webhookd, a lightweight webhook server that executes
# shell scripts in response to HTTP requests. It's used to trigger server
# updates when changes are pushed to the git repository.
#
# How it works:
#   1. CI/CD pipeline calls POST /update (via Caddy reverse proxy)
#   2. Webhookd executes scripts/update.sh
#   3. The script pulls changes, rebuilds, and restarts the Minecraft server
#
# Documentation: https://github.com/ncarlier/webhookd
# =============================================================================

FROM ncarlier/webhookd:1.19.0-distrib
USER root

# =============================================================================
# Docker Socket Access
# =============================================================================
# Webhookd needs to run `docker compose` commands to rebuild and restart
# containers. This requires access to the Docker socket.
#
# CUSTOMIZE: The GID 988 is the docker group on some systems. You may need
# to change this to match your host's docker group GID:
#   $ getent group docker | cut -d: -f3
# =============================================================================
RUN delgroup ping \
    && addgroup --gid 988 docker \
    && addgroup webhookd docker \
    && mkdir /.docker \
    && chown webhookd:webhookd /.docker

# =============================================================================
# Install Required Tools
# =============================================================================
# These tools are needed by the update script:
#   - curl: HTTP requests (debugging, health checks)
#   - file: File type detection
#   - git, git-lfs: Clone and pull repository changes
#   - zip: Archive handling if needed
# =============================================================================
RUN apk add --no-cache \
      curl  \
      file \
      git \
      git-lfs \
      zip \
    && mkdir -p /opt/webhookd/home \
    && chown -R 1000:1000 /opt/webhookd/home

# Set HOME directory for git and other tools that need it
ENV HOME=/opt/webhookd/home
WORKDIR /opt/webhookd/home

# =============================================================================
# Webhook Scripts
# =============================================================================
# WHD_HOOK_SCRIPTS tells webhookd where to find executable scripts.
# Scripts are exposed as HTTP endpoints: scripts/update.sh -> POST /update
# CUSTOMIZE: Add more scripts to scripts/ for additional webhook endpoints
# =============================================================================
ENV WHD_HOOK_SCRIPTS=/opt/webhookd/scripts
WORKDIR /opt/webhookd
COPY --chown=webhookd:webhookd --chmod=555 scripts/ scripts/

# Run as non-root user for security
USER webhookd
ENTRYPOINT ["webhookd"]
