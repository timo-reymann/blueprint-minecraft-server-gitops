#!/bin/bash
# =============================================================================
# Paper Server Entrypoint Script
# =============================================================================
# This script runs when the container starts. It:
#   1. Renders Discord plugin configuration from environment variables
#   2. Starts the Minecraft server
#
# Why use an entrypoint script instead of just running java directly?
#   - Environment variables can be injected at runtime (secrets management)
#   - Template files can be rendered with actual credentials
#   - Startup logging helps with debugging
#
# CUSTOMIZE: Add additional startup tasks here (e.g., backup restoration,
#            additional config templating, health checks)
# =============================================================================
set -e  # Exit immediately if any command fails

# =============================================================================
# Discord Plugin Configuration
# =============================================================================
# The BasicDiscordRelay plugin bridges chat between Minecraft and Discord.
# Credentials are injected via environment variables (see docker-compose.yml)
# and rendered into the plugin's config file using envsubst.
#
# Template location: plugins/DiscordRelay/config.yml.template
# CUSTOMIZE: If you remove the Discord plugin, you can remove this section
# =============================================================================
echo "=== Rendering Discord configuration ==="

# envsubst replaces ${VAR} placeholders in the template with actual values
envsubst < /opt/minecraft-server/plugins/DiscordRelay/config.yml.template > /opt/minecraft-server/plugins/DiscordRelay/config.yml

# Verify that Discord credentials were provided
if [ -n "$DISCORD_BOT_TOKEN" ] && [ -n "$DISCORD_CHANNEL_ID" ]; then
    echo "Discord config rendered successfully"
    echo "  Token: ********************"  # Masked for security
    echo "  Channel ID: ${DISCORD_CHANNEL_ID}"
else
    # Server will still start, but Discord integration won't work
    echo "WARNING: Discord environment variables not set"
    echo "  DISCORD_BOT_TOKEN: ${DISCORD_BOT_TOKEN:-(not set)}"
    echo "  DISCORD_CHANNEL_ID: ${DISCORD_CHANNEL_ID:-(not set)}"
fi

# =============================================================================
# Start Minecraft Server
# =============================================================================
# Using 'exec' replaces this shell process with the Java process, ensuring:
#   - Signals (SIGTERM, etc.) are sent directly to the server
#   - Clean shutdown when container stops
#   - PID 1 is the Java process (proper container behavior)
#
# CUSTOMIZE: Add JVM flags here for memory tuning, garbage collection, etc.
# Example: exec java -Xms4G -Xmx4G -XX:+UseG1GC -jar paper.jar
# See: https://docs.papermc.io/paper/aikars-flags
# =============================================================================
echo ""
echo "=== Starting Paper server ==="
exec java -jar /opt/minecraft-server/paper.jar