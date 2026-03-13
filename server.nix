{ config, pkgsMc, ... }: {

  age.secrets.rcon-password = {
    file = ./secrets/rcon-password.age;
    owner = "minecraft";
  };

  # Minecraft server definition (Fabric 1.21.11) 
  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;
    environmentFile = config.age.secrets.rcon-password.path; #Tells nix-minecraft where rcon-password is.

    servers.main = {
      enable = true;
      autoStart = true;

      # Use the minecraft-enabled pkgs set
      package = pkgsMc.fabricServers.fabric-1_21_11;

      jvmOpts = "-Xms8G -Xmx12G";

      serverProperties = {
        server-port = 25565;
        motd = "Monk loves Michael";
        online-mode = true;
        max-players = 20;
        difficulty = 3;
        white-list = true;
        view-distance = 32;
        enable-rcon = true;
        "rcon.password" = "@RCON_PASSWORD@";
        "rcon.port" = 25575;
      };

      # mods
      symlinks = {
      "mods" = ./minecraft/mods;
      "datapacks" = ./minecraft/datapacks;
      };

    };
  };
}
