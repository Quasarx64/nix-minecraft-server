{ config, pkgs, ... }:

let
  backupScript = pkgs.writeShellScript "minecraft-backup" ''
    SERVERS_DIR="/srv/minecraft"
    BACKUP_BASE="/srv/minecraft-backups"
    RCON_PASS=$(cat ${config.age.secrets.rcon-password.path} | grep RCON_PASSWORD | cut -d= -f2)

    for SERVER_DIR in "$SERVERS_DIR"/*/; do
      SERVER_NAME=$(basename "$SERVER_DIR")
      BACKUP_DIR="$BACKUP_BASE/$SERVER_NAME"
      PROPERTIES="$SERVER_DIR/server.properties"

      # Skip if no server.properties (not a valid server)
      if [ ! -f "$PROPERTIES" ]; then
        echo "Skipping $SERVER_NAME: no server.properties found"
        continue
      fi

      # Get RCON port from server.properties
      RCON_PORT=$(${pkgs.gnugrep}/bin/grep -E '^rcon\.port=' "$PROPERTIES" | cut -d= -f2)
      if [ -z "$RCON_PORT" ]; then
        echo "Skipping $SERVER_NAME: RCON port not configured"
        continue
      fi

      # Get world folder name (defaults to "world")
      LEVEL_NAME=$(${pkgs.gnugrep}/bin/grep -E '^level-name=' "$PROPERTIES" | cut -d= -f2)
      LEVEL_NAME=''${LEVEL_NAME:-world}
      WORLD_DIR="$SERVER_DIR/$LEVEL_NAME"

      if [ ! -d "$WORLD_DIR" ]; then
        echo "Skipping $SERVER_NAME: world folder '$LEVEL_NAME' not found"
        continue
      fi

      echo "Backing up $SERVER_NAME world '$LEVEL_NAME' (RCON port $RCON_PORT)..."

      # Pause autosave and flush to disk
      if ! ${pkgs.mcrcon}/bin/mcrcon -H 127.0.0.1 -P "$RCON_PORT" -p "$RCON_PASS" -c "save-off" -c "save-all flush" 2>/dev/null; then
        echo "Skipping $SERVER_NAME: server not responding to RCON"
        continue
      fi

      sleep 5  # Wait for save to complete
      mkdir -p "$BACKUP_DIR"

      # Backup world
      mkdir -p "$BACKUP_DIR/latest"
      ${pkgs.rsync}/bin/rsync -avz --delete --chmod=D755,F644 "$WORLD_DIR/" "$BACKUP_DIR/latest/$LEVEL_NAME/"

      # Re-enable autosave
      ${pkgs.mcrcon}/bin/mcrcon -H 127.0.0.1 -P "$RCON_PORT" -p "$RCON_PASS" -c "save-on"

      echo "Backup of $SERVER_NAME completed at $(date)"
    done
  '';
in
{
  systemd.tmpfiles.rules = [
    "d /srv/minecraft-backups 0755 minecraft users -"
  ];

  systemd.services.minecraft-backup = {
    description = "Minecraft World Backup";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = backupScript;
      User = "minecraft";
    };
  };

  systemd.timers.minecraft-backup = {
    description = "Run Minecraft backup hourly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 00,12:00:00";  # Twice daily at midnight and noon
      Persistent = true;  # Run if missed while system was off
    };
  };
}
