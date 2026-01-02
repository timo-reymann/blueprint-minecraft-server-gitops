# =============================================================================
# Paper Minecraft Server - Dockerfile
# =============================================================================
# Multi-stage build that creates an optimized Minecraft server image:
#   Stage 1 (download)   - Downloads the Paper server JAR
#   Stage 2 (rcon-cli)   - Downloads rcon-cli for remote console commands
#   Stage 3 (bootstrap)  - Initializes server, copies configs, runs player setup
#   Stage 4 (final)      - Minimal runtime image with all artifacts
#
# CUSTOMIZE: Search for "CUSTOMIZE" comments below for common modifications
# =============================================================================

# =============================================================================
# Stage 1: Download Paper Server JAR
# =============================================================================
# Downloads the Paper server software. Paper is a high-performance fork of
# Spigot with additional optimizations and bug fixes.
# CUSTOMIZE: Update paper_download_url when new versions are released
#   - Get URLs from: https://papermc.io/downloads/paper
#   - Or use API: https://api.papermc.io/v2/projects/paper
# =============================================================================
FROM curlimages/curl AS download
WORKDIR /papermc
ARG paper_download_url=https://fill-data.papermc.io/v1/objects/d4f897545310f31e623d9680786b25dd20a9989e139db050d1aacf81ecafd05c/paper-1.21.10-113.jar
RUN curl -L ${paper_download_url} -o paper.jar

# =============================================================================
# Stage 2: Download RCON CLI
# =============================================================================
# RCON (Remote Console) allows sending commands to the server programmatically.
# Used by webhookd to notify players before server restarts.
# Documentation: https://github.com/gorcon/rcon-cli
# CUSTOMIZE: Update rcon_cli_version for newer releases
# CUSTOMIZE: Change password in config.yaml (must match server.properties rcon.password)
# =============================================================================
FROM curlimages/curl AS rcon-cli
WORKDIR /rcon-cli
ARG rcon_cli_version=0.10.3
RUN curl -L https://github.com/gorcon/rcon-cli/releases/download/v${rcon_cli_version}/rcon-${rcon_cli_version}-amd64_linux.tar.gz -o /tmp/rcon.tar.gz \
    && tar -xvzf /tmp/rcon.tar.gz \
    && mkdir -p bin/ \
    && mv rcon-${rcon_cli_version}-amd64_linux/rcon bin/rcon \
    && rm -rf rcon-${rcon_cli_version}-amd64_linux \
    # CUSTOMIZE: Change 'secret' to match rcon.password in server.properties
    && echo -e "default:\n  address: 127.0.0.1:25575\n  password: secret\n" > config.yaml

# =============================================================================
# Stage 3: Bootstrap - Initialize Server and Configure
# =============================================================================
# This stage:
#   1. Runs Paper once to generate default configs and accept EULA
#   2. Copies your customized configuration files
#   3. Runs manage_players.py to generate whitelist from players.yml
#
# Why bootstrap in a build stage?
#   - Server starts faster (no first-run initialization)
#   - Configuration is baked into the image (immutable infrastructure)
#   - Player whitelist is generated at build time from GitOps source
# =============================================================================
FROM eclipse-temurin:21 AS bootstrap
WORKDIR /opt/minecraft-server

# Python is needed for manage_players.py (whitelist generation)
RUN apt-get update \
    && apt-get install -y python3 python3-pip python3-yaml  \
    && rm -rf /var/lib/apt/lists/*

# Copy Paper JAR and run initial bootstrap to generate default files
COPY --from=download /papermc/paper.jar .
RUN java -jar /opt/minecraft-server/paper.jar \
    && echo "eula=true" > eula.txt  # Accept Minecraft EULA (https://aka.ms/MinecraftEULA)

# === Server Configuration ===
# CUSTOMIZE: Edit these files in the paper/ directory to configure your server
COPY spigot.yml .           # Spigot-specific settings (mob spawning, etc.)
COPY server-icon.png .      # 64x64 PNG shown in server list
COPY server.properties .    # Core Minecraft server settings
COPY config config          # Paper-specific config (paper-global.yml, etc.)

# === Plugins ===
# CUSTOMIZE: Add/remove plugin JARs in paper/plugins/
# Plugin configs are in paper/plugins/<PluginName>/
COPY plugins/ ./plugins/

# === Player Management (GitOps) ===
# Generates whitelist.json from players.yml and updates related configs
# CUSTOMIZE: Edit players.yml to manage your player whitelist
COPY players.yml .
COPY manage_players.py .
RUN python3 manage_players.py

# =============================================================================
# Stage 4: Final Runtime Image
# =============================================================================
# Minimal image containing only what's needed to run the server.
# Runs as non-root user (UID 1000) for security.
# =============================================================================
FROM eclipse-temurin:21
USER root

# gettext-base provides 'envsubst' for template rendering in entrypoint.sh
# (Used to inject Discord credentials into plugin config)
RUN apt-get update \
    && apt-get install -y gettext-base  \
    && rm -rf /var/lib/apt/lists/*

# Run as non-root for security (UID 1000 is conventional for container users)
USER 1000

# Install RCON CLI for remote server commands
WORKDIR /opt/rcon-cli/bin
ENV PATH="$PATH:/opt/rcon-cli/bin"
COPY --chown=1000:1000 --from=rcon-cli /rcon-cli /opt/rcon-cli

# Copy the fully configured server from bootstrap stage
WORKDIR /opt/minecraft-server
COPY --chown=1000:1000 --from=bootstrap /opt/minecraft-server/ ./
COPY --chown=1000:1000 --chmod=755 entrypoint.sh /opt/minecraft-server/

# Server starts via entrypoint.sh which handles environment variable injection
ENTRYPOINT ["/opt/minecraft-server/entrypoint.sh"]
