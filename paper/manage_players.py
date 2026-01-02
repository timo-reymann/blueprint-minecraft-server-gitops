#!/usr/bin/env python3
"""
Minecraft Server Player Management Script

This script dynamically manages players based on players.yml configuration:
- Generates whitelist.json from players list
- Updates server.properties max-players count
- Updates KeepInvIndividual plugin configuration based on per-player settings
"""

import json
import yaml
import re
from pathlib import Path
from typing import List, Dict


def load_players(players_file: Path) -> List[Dict]:
    """Load players from players.yml file."""
    if not players_file.exists():
        print(f"Warning: {players_file} does not exist")
        return []

    with open(players_file, 'r') as f:
        data = yaml.safe_load(f)
        return data.get('players', [])


def generate_whitelist(players: List[Dict], output_file: Path):
    """Generate whitelist.json from players list."""
    whitelist = []
    for player in players:
        whitelist.append({
            "uuid": player['uuid'],
            "name": player['name']
        })

    with open(output_file, 'w') as f:
        json.dump(whitelist, f, indent=2)

    print(f"Generated whitelist.json with {len(whitelist)} players")


def update_server_properties(players: List[Dict], properties_file: Path):
    """Update max-players in server.properties based on player count."""
    if not properties_file.exists():
        print(f"Warning: {properties_file} does not exist")
        return

    with open(properties_file, 'r') as f:
        lines = f.readlines()

    player_count = len(players)
    updated = False

    for i, line in enumerate(lines):
        if line.startswith('max-players='):
            lines[i] = f'max-players={player_count}\n'
            updated = True
            break

    with open(properties_file, 'w') as f:
        f.writelines(lines)

    if updated:
        print(f"Updated server.properties: max-players={player_count}")
    else:
        print("Warning: max-players property not found in server.properties")


def update_keepinv_config(players: List[Dict], keepinv_file: Path):
    """Update KeepInvIndividual plugin configuration based on player settings."""
    if not keepinv_file.exists():
        print(f"Warning: {keepinv_file} does not exist")
        keepinv_file.parent.mkdir(parents=True, exist_ok=True)

    # Build list of players who should keep inventory
    players_with_keepinv = []
    for player in players:
        if player.get('keepInventoryEnabled', False):
            players_with_keepinv.append(player['uuid'])

    # Create the keepInvList.yml structure
    keepinv_data = {
        'players': players_with_keepinv
    }

    with open(keepinv_file, 'w') as f:
        yaml.dump(keepinv_data, f, default_flow_style=False)

    print(f"Updated keepInvList.yml with {len(players_with_keepinv)} players")


def main():
    # Define paths
    base_dir = Path(__file__).parent
    players_file = base_dir / 'players.yml'
    whitelist_file = base_dir / 'whitelist.json'
    properties_file = base_dir / 'server.properties'
    keepinv_file = base_dir / 'plugins' / 'KeepInvIndividual' / 'keepInvList.yml'

    print("=" * 60)
    print("Minecraft Server Player Management")
    print("=" * 60)

    # Load players
    players = load_players(players_file)

    if not players:
        print("No players found in players.yml")
        return

    print(f"Loaded {len(players)} players from {players_file}")

    # Generate whitelist
    generate_whitelist(players, whitelist_file)

    # Update server.properties
    update_server_properties(players, properties_file)

    # Update KeepInvIndividual config
    update_keepinv_config(players, keepinv_file)

    print("=" * 60)
    print("Player management completed successfully!")
    print("=" * 60)


if __name__ == '__main__':
    main()
