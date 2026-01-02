#!/usr/bin/env bash
# =============================================================================
# GitOps Update Handler - Webhookd Script
# =============================================================================
# This script is executed by webhookd when a deployment webhook is received.
# It performs a zero-downtime(ish) update of the Minecraft server:
#
#   1. Validates required parameters
#   2. Pulls latest changes from git
#   3. Rebuilds Docker images with new configuration
#   4. Notifies in-game players of the impending restart
#   5. Waits for players to reach a safe location
#   6. Restarts the server with the new image
#
# Called by: update.sh (via CI/CD pipeline)
# Documentation: https://github.com/ncarlier/webhookd
#
# CUSTOMIZE: Update the git remote URL and notification message below
# =============================================================================

# Show Docker build output in plain text (easier to debug in webhook logs)
export BUILDKIT_PROGRESS=plain

# =============================================================================
# Helper Functions
# =============================================================================
# These functions handle output formatting and error handling for webhookd.
# Webhookd translates exit codes to HTTP status codes (exit code + 300).
# =============================================================================

# @description Exit with a message and HTTP status exit code for webhookd
# @arg $1 HTTP Status to exit with
# @arg $2 Message to print before exiting
# @exit ($1 - 300) HTTP status for webhookd translated to exit code
exit_with_message() {
  local http_status; http_status="$1"
  local message; message="$2"

  echo "$message" >&2
  # Webhookd converts exit codes to HTTP status: exit_code = http_status - 300
  # So exit 100 = HTTP 400, exit 200 = HTTP 500
  exit "$((http_status-300))"
}

# @description Require a parameter to be set
# @arg $1 Name of the required environment variable
# @exit 100 If the parameter is missing
# @stderr Error message, if the parameter is missing
require_parameter() {
  local name; name="$1"

  if [ -z "${!name}" ];
  then
    exit_with_message 400 "Missing parameter ${name}"
  fi
}

# @description Output to stderr for webhookd
# @stderr Message
output() {
    # Webhookd captures stderr for the response body
    echo "$@" >&2
}

# @description Print spacer between sections
# @stderr Spacer output
print_spacer() {
  output " "
}

# @description Print heading for a logical section
# @stderr Heading for the section
print_section() {
  local heading; heading="$1"
  local heading_length; heading_length=${#heading}
  local pad_count_end; pad_count_end=$((30-heading_length))
  output "$(printf '=%.0s' {1..5}) $(printf "%-10s" "${heading}") $(printf '=%.0s' $(seq "${pad_count_end}"))"
}

# =============================================================================
# Parameter Validation
# =============================================================================
# These parameters are passed from update.sh via POST body
# =============================================================================
require_parameter "gitlab_token"      # CI token for git authentication
require_parameter "commit_message"    # For logging purposes
require_parameter "restart_in_seconds" # Delay before restart

# Verify we're in the right directory (mounted from docker-compose.yml)
cd "/opt/minecraft" 2>/dev/null || exit_with_message 400 "Folder does not exist"
output "Valid."
print_spacer

# =============================================================================
# Step 1: Pull Latest Changes from Git
# =============================================================================
# Uses a temporary remote with the CI token for authentication.
# CUSTOMIZE: Update the gitlab.com URL to your repository
# =============================================================================
print_section "Pull changes"
# Mark directory as safe (required when running as different user)
git config --global --add safe.directory /opt/minecraft
# Remove any existing CI remote (from previous runs)
git remote rm ci || true
# CUSTOMIZE: Replace with your GitLab/GitHub repository URL
git remote add ci https://gitlab-ci-token:${gitlab_token}@gitlab.com/your-user/your-server.git
# shellcheck disable=SC2154
git pull ci main || exit_with_message 500 "Could not pull changes"
# Clean up the temporary remote (don't leave tokens in git config)
git remote rm ci
print_spacer

# =============================================================================
# Step 2: Rebuild Docker Images
# =============================================================================
# Rebuilds the Paper server image with any new plugins, configs, or players
# =============================================================================
print_section "Pull image"
# shellcheck disable=SC2154
docker compose build paper || exit_with_message 500 "Could not build images"
print_spacer

# =============================================================================
# Step 3: Notify Players In-Game
# =============================================================================
# Uses RCON to send a chat message warning players about the restart.
# CUSTOMIZE: Modify the message text and colors (§ codes are Minecraft formatting)
#   §b = aqua, §6 = gold, §c = red, §a = green
#   See: https://minecraft.wiki/w/Formatting_codes
# =============================================================================
print_section "Notify users"
docker compose exec paper rcon -c /opt/rcon-cli/config.yaml "say §bServer is restarting in §630 seconds§b! Make sure you are are at a safe location for a reconnect"
print_spacer

# =============================================================================
# Step 4: Wait for Players to Prepare
# =============================================================================
# Gives players time to reach a safe location before disconnect
# =============================================================================
print_section "Wait for ${restart_in_seconds} seconds"
sleep ${restart_in_seconds}
print_spacer

# =============================================================================
# Step 5: Restart Server with New Image
# =============================================================================
# Recreates the container with the newly built image
# =============================================================================
print_section "Update container"
# shellcheck disable=SC2154
docker compose --progress plain up -d paper || exit_with_message 500 "Could not start up containers"
docker compose restart paper || exit_with_message 500 "could not restart server"
print_spacer

# Script completes with exit 0, which webhookd translates to HTTP 300
# (not a real HTTP status, but indicates success)

