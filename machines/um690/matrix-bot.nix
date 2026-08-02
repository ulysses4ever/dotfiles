{ pkgs, ... }:

let
  matrix-bot = pkgs.writeShellScriptBin "matrix-bot" ''
    exec ${pkgs.python3}/bin/python3 ${./matrix-bot.py} "$@"
  '';
in
{
  users.users.matrix-bot = {
    isSystemUser = true;
    group = "matrix-bot";
    description = "GitHub→Matrix webhook bot";
  };
  users.groups.matrix-bot = {};

  systemd.services.matrix-bot = {
    description = "GitHub webhook to Matrix notification bot";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${matrix-bot}/bin/matrix-bot";
      User = "matrix-bot";
      Group = "matrix-bot";
      # Secrets: MATRIX_TOKEN and WEBHOOK_SECRET (and optionally
      # MATRIX_HOMESERVER, MATRIX_ROOM_ID, PORT, HIGH_PRIORITY_LABEL)
      EnvironmentFile = "/etc/matrix-bot/env";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
    };
  };
}
