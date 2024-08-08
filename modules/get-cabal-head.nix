{ config, lib, pkgs, ... }:

{
  systemd.services."get-cabal-head" = {
    enable = true;
    description = "Get cabal pre-release daily";
    path = with pkgs; [ wget gnutar gzip ];
    requires = [ "network-online.target" ];
    script = ''
      set -eu
      #until ping -c1 github.com &>/dev/null; do
      #    sleep 20
      #done
      cd "$HOME/.local/bin"
      wget https://github.com/haskell/cabal/releases/download/cabal-head/cabal-head-Linux-static-x86_64.tar.gz
      rm -f cabal
      tar -xzf ./cabal-head-Linux-static-x86_64.tar.gz
      rm -f ./cabal-head-Linux-static-x86_64.tar.gz
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "artem";
    };
  };

  # Run get-cabal-head daily at midnight or any time later if it hasn't been run yet
  systemd.timers."get-cabal-head" = {
    wantedBy = [ "timers.target" ];
      timerConfig = {
        Unit = "get-cabal-head.service";
        OnCalendar = "daily";
        Persistent = true;
      };
  };

}
