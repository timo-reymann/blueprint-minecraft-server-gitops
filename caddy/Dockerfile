# =============================================================================
# Caddy - Reverse Proxy with Automatic HTTPS
# =============================================================================
# Caddy serves two purposes in this stack:
#   1. Reverse proxy: Routes /update requests to webhookd for GitOps deployments
#   2. Static file server: Serves a landing page at the root domain
#
# Caddy automatically obtains and renews Let's Encrypt TLS certificates,
# so HTTPS works out of the box with zero configuration.
#
# Documentation: https://caddyserver.com/docs/
# =============================================================================

FROM caddy:2-alpine

# =============================================================================
# Caddy Configuration
# =============================================================================
# The Caddyfile defines routing rules, TLS settings, and authentication.
# CUSTOMIZE: Edit Caddyfile to change domain, add routes, or modify auth
# =============================================================================
COPY Caddyfile /etc/caddy/Caddyfile

# =============================================================================
# Static Files
# =============================================================================
# Files in rootfs/ are served at the domain root (e.g., https://example.com/)
# CUSTOMIZE: Replace rootfs/index.html with your own landing page
# =============================================================================
RUN mkdir -p /opt/caddy/rootfs
COPY rootfs/ /opt/caddy/rootfs/

WORKDIR /opt/caddy

# Note: Ports 80 and 443 are exposed via docker-compose.yml
# Port 8080 was originally exposed here but is not used in current config
EXPOSE 8080

# Caddy automatically loads /etc/caddy/Caddyfile on startup