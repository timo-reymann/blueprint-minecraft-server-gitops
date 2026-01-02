#!/bin/env sh
# =============================================================================
# GitOps Deployment Trigger Script
# =============================================================================
# This script is called by CI/CD (e.g., GitLab CI) to trigger a server update.
# It sends a webhook request to the server, which then:
#   1. Pulls the latest git changes
#   2. Rebuilds the Docker images
#   3. Notifies players of the restart
#   4. Restarts the Minecraft server
#
# Usage:
#   Called automatically by CI/CD pipeline, or manually:
#   $ CI_JOB_TOKEN=xxx CI_COMMIT_MESSAGE="test" ./update.sh
#
# CUSTOMIZE: Update the URL, authorization, and timing below
# =============================================================================

# CUSTOMIZE: Replace with your server's domain
# This URL is proxied through Caddy to webhookd (see Caddyfile)
#
# Curl flags explained:
#   --http1.1          Force HTTP/1.1 (some proxies have issues with HTTP/2)
#   -sS                Silent but show errors
#   -XPOST             POST request to trigger the webhook
#   --fail-with-body   Exit with error if HTTP status indicates failure
#
# Webhookd headers:
#   X-Hook-Mode: buffered   Wait for script to complete before responding
#   X-Hook-Timeout: 300     Allow up to 5 minutes for the update
#   See: https://github.com/ncarlier/webhookd
#
# Authentication:
#   CUSTOMIZE: Replace Authorization header with your Base64-encoded credentials
#   Generate with: echo -n "username:password" | base64
#   Must match basic_auth in Caddyfile
#
# Parameters (passed to webhookd/scripts/update.sh):
#   gitlab_token        GitLab CI token for pulling the repo
#   commit_message      Shown in logs for debugging
#   restart_in_seconds  CUSTOMIZE: Delay before restart (gives players time to prepare)

curl https://kellercamp.de/update \
    --http1.1 \
    -sS \
    -XPOST \
    --header "X-Hook-Mode: buffered" \
    --header "X-Hook-Timeout: 300" \
    --header "Authorization: Basic <basic auth here>" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    --fail-with-body \
    -d "gitlab_token=${CI_JOB_TOKEN}" \
    -d "commit_message=${CI_COMMIT_MESSAGE}" \
    -d "restart_in_seconds=30"
