# finance.nix — the family's books at https://money.pelenitsyn.site/ and their
# receipts at https://paperless.pelenitsyn.site/, both behind one Cloudflare
# Access application, "money" (2026-10-17). The plan behind it, from the move
# off AndroMoney: ~/Dev/accounting/PLAN.md.
#
# hledger-web has no authentication of its own, and the eight CI runners on
# this box can reach any TCP port on it (brightspace-web.nix makes the same
# point), so it listens on a Unix socket and binds no port at all. The socket
# and its directory belong to the group finance-web, whose only members are
# the tunnel's dynamic user and, once it exists, the entry page. Everyone else
# comes in through Access.
#
# The Access application is the one part not declared here. It covers both
# hostnames and admits the policy "money: family" (the two addresses of "ArJu
# emails", copied); it was made through the API with
# ~/.config/cloudflare/dns-token on 2026-10-17, before the hostnames' DNS
# records, which `cloudflared tunnel route dns` made the same day.
#
# Nothing here lives on /: the books are a git repository in ~/data/finance,
# and Paperless keeps its database, documents, exports and scratch space in
# ~/data/paperless, bound to /var/lib/paperless as immich's data is bound to
# /media/immich. Its module makes every unit RequiresMountsFor= its paths, so
# it cannot come up against an empty directory on / the way docker could.
# hledger-web sees the books and nothing else of artem's, and has no network
# beyond its socket.
{ config, lib, pkgs, inputs, ... }:

let
  tunnel = "2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19";
  host = "money.pelenitsyn.site";
  paperlessHost = "paperless.pelenitsyn.site";
  repo = "/home/artem/data/finance";
  socket = "/run/hledger-web/web.sock";
  # The showroom: the fork on fictional books, open to the world.
  showroomHost = "showroom.pelenitsyn.site";
  showroomDir = "/home/artem/data/showroom";
  showroomSocket = "/run/hledger-showroom/web.sock";

  # The CLI: both nixpkgs pins (26.05 and unstable) ship 1.52.0. 1.52.2 and
  # 1.52.3 fix two XSS holes in hledger-web's add form and stop a newline in a
  # submitted description from being written into the journal; 1.52.4 avoids a
  # denial-of-service in aeson. Upstream's static build, until nixpkgs catches up.
  hledger = pkgs.stdenvNoCC.mkDerivation {
    pname = "hledger-static";
    version = "1.52.4";
    src = pkgs.fetchurl {
      url = "https://github.com/hledgerorg/hledger/releases/download/1.52.4/hledger-linux-x64.tar.gz";
      sha256 = "0fk4d65midmap6zik6r1rpd6ynlxaq17a1s3irjvfqp1i102wspp";
    };
    # The tarball has no top-level directory.
    sourceRoot = ".";
    dontBuild = true;
    installPhase = ''
      install -Dm755 -t $out/bin hledger hledger-ui hledger-web
      install -Dm644 -t $out/share/man/man1 *.1
    '';
  };
  # hledger-web itself comes from our fork (~/Dev/hledger, branch web-mobile,
  # pinned by the flake input hledger-src): upstream's main line (1.99) plus a
  # phone layout, which the family will not do without. hledger-lib and hledger
  # are built from the same commit. Each package directory is copied under its
  # own name, as ~/Dev/accounting/hosting/hledger-from-source.nix does, so the
  # builds are shared with that recipe's. The git tree lacks the command docs
  # the CLI embeds; they are stubbed, which only matters to `hledger help`.
  hledgerWeb =
    let
      hlib = pkgs.haskell.lib;
      relax = p: hlib.dontCheck (hlib.doJailbreak p);
      dir = name: builtins.path { path = "${inputs.hledger-src}/${name}"; inherit name; };
      stubDocs = p: hlib.overrideCabal p (o: {
        postPatch = (o.postPatch or "") + ''
          for f in $(grep -o 'embeddedfiles/[^"]*' Hledger/Cli/DocFiles.hs | sort -u); do
            mkdir -p "$(dirname "$f")"
            if [ ! -e "$f" ]; then rm -f "$f"; echo "Documentation is not generated in this build." > "$f"; fi
          done
        '';
      });
      hp = pkgs.haskellPackages.extend (self: super: {
        hledger-lib = relax (self.callCabal2nix "hledger-lib" (dir "hledger-lib") { });
        hledger = stubDocs (relax (self.callCabal2nix "hledger" (dir "hledger") { }));
        hledger-web = relax (self.callCabal2nix "hledger-web" (dir "hledger-web") { });
      });
    in
    hp.hledger-web;
in
{
  environment.systemPackages = [ hledger ];

  users.groups.finance-web = { };

  systemd.services.hledger-web-family = {
    description = "hledger-web for the family's books, at ${host} behind Cloudflare Access";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    unitConfig.RequiresMountsFor = repo;

    serviceConfig = {
      # artem's, like brightspace-web: the books are his checkout.
      User = "artem";
      # The socket takes the process's group and, with this umask, mode 0770.
      Group = "finance-web";
      UMask = "0007";
      # Removed on every stop, so a stale socket never outlives the process.
      RuntimeDirectory = "hledger-web";
      RuntimeDirectoryMode = "0750";
      # Since 1.52.4 it keeps its session-cookie key under $XDG_CACHE_HOME and
      # exits if it cannot create it, which ProtectHome's read-only ~ forbids.
      # Kept in RAM, in a directory the group cannot enter; a new key after a
      # restart only means reloading a form left open across it.
      Environment = [ "XDG_CACHE_HOME=/run/hledger-web/cache" ];
      ExecStartPre = "${pkgs.coreutils}/bin/install -d -m 0700 /run/hledger-web/cache";
      ExecStart = lib.escapeShellArgs [
        "${hledgerWeb}/bin/hledger-web"
        "--serve"                      # web UI and JSON API
        "--allow=add"                  # family members can only append
        "--socket=${socket}"
        "--base-url=https://${host}"
        # The one root: declarations, the AndroMoney history, the imports, and
        # the entries appended at its end. Its unfiltered journal page is 10 MB;
        # the entry page in front will send phones to filtered views instead.
        "--file=${repo}/main.journal"
        # The family's own look on top of the built-in one, versioned with the
        # books; hledger-web reads it on every request, so edits need no restart.
        "--css=${repo}/web.css"
      ];
      Restart = "on-failure";
      RestartSec = 5;

      ProtectHome = "tmpfs";
      BindPaths = [ repo ];
      ProtectSystem = "strict";
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      RestrictAddressFamilies = [ "AF_UNIX" ];
      IPAddressDeny = "any";
    };
  };

  # The tunnel runs as a dynamic user; joining the group is what lets it
  # through /run/hledger-web to the socket.
  systemd.services."cloudflared-tunnel-${tunnel}".serviceConfig.SupplementaryGroups = [ "finance-web" ];

  services.cloudflared.tunnels.${tunnel}.ingress = {
    # Until the entry page exists. Then this becomes the entry page's socket,
    # and the entry page forwards everything but its own pages to hledger-web.
    ${host} = { service = "unix:${socket}"; };
    # The showroom is public: no Access application covers this hostname.
    ${showroomHost} = { service = "unix:${showroomSocket}"; };
    # Paperless has its own login on top of Access, so local reachability on
    # its port is not the open door hledger-web's would be.
    ${paperlessHost} = { service = "http://localhost:${toString config.services.paperless.port}"; };
  };

  # Receipts, for returns and warranties. Photos arrive from the entry page
  # through the API (a token in ~/.config/finance, never in the store); people
  # look them up in Paperless's own UI.
  services.paperless = {
    enable = true;
    address = "127.0.0.1";
    # dataDir stays /var/lib/paperless: the bind below puts it on the data disk.
    # Initial password of the "admin" user, read by systemd as root; family
    # accounts are made in the UI.
    passwordFile = "/home/artem/.config/finance/paperless-admin-password";
    settings = {
      # CSRF's trusted origin. Hosts are limited to this name, to which
      # Paperless always adds localhost: what the entry page will call.
      PAPERLESS_URL = "https://${paperlessHost}";
      PAPERLESS_ALLOWED_HOSTS = paperlessHost;
      PAPERLESS_OCR_LANGUAGE = "eng";
      PAPERLESS_TIME_ZONE = config.time.timeZone;
      # OCR's working files, off / like the rest (the default is /tmp).
      PAPERLESS_SCRATCH_DIR = "/var/lib/paperless/scratch";
    };
    # A portable copy of every document and its metadata, nightly at 01:30,
    # into ~/data/paperless/export.
    exporter.enable = true;
  };

  # Not dataDir = ~/data/paperless directly: systemd-tmpfiles refuses to
  # create media/ and consume/ there, since reaching them means stepping from
  # artem's ~/data into a paperless-owned directory, an "unsafe path
  # transition" (2026-10-17). Through a bind the path from / never passes
  # through artem's directories. Mounting a bind requires its source's mount,
  # ~/data, by itself; nofail as for server.nix's binds.
  fileSystems."/var/lib/paperless" = {
    device = "/home/artem/data/paperless";
    options = [ "bind" "nofail" ];
    fsType = "none";
  };

  # The books, committed and pushed to their private GitHub repository every
  # hour: the off-box copy. Backup first, check second, so a broken entry is
  # still saved; a failed push or check fails the unit, which is what
  # `systemctl --failed` will show. The push uses the repository's own deploy
  # key (core.sshCommand in its .git/config), which can write to that
  # repository and nothing else.
  systemd.services.finance-backup = {
    description = "Write the month's recurring entries, commit ~/data/finance and push it to GitHub";
    unitConfig.RequiresMountsFor = repo;
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = with pkgs; [ git openssh coreutils hledger python3 ];
    serviceConfig = {
      Type = "oneshot";
      User = "artem";
      WorkingDirectory = repo;
    };
    script = ''
      # The recurring entries due from today to the end of the month, as
      # pending entries, like AndroMoney's; idempotent (tools/recur.py).
      python3 tools/recur.py -f main.journal
      git add -A
      if ! git diff --cached --quiet; then
        git commit -q -m "auto: $(date -Iminutes)"
      fi
      if git remote | grep -q .; then
        git push -q origin HEAD
      fi
      # No ordereddates: phone entries and backfilled statements arrive out
      # of date order by design.
      hledger -f main.journal check --strict
    '';
  };
  systemd.timers.finance-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      RandomizedDelaySec = "5m";
      Persistent = true;
    };
  };

  # The family's budget sheet, fed from the books every evening
  # (tools/budget_push.py): the month's day rows and its Hard and Soft
  # cells, nothing else on the sheet (Julia's rule). It writes as a Google
  # service account the sheet is shared with; the account's key is in
  # ~/.config/finance, never in the store. In a month's first days the
  # previous month is written again, for entries that came late.
  systemd.services.budget-push = {
    description = "Push the month's actuals from the books into the family's budget sheet";
    unitConfig.RequiresMountsFor = repo;
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ hledger (pkgs.python3.withPackages (ps: [ ps.google-auth ps.requests ])) ];
    serviceConfig = {
      Type = "oneshot";
      User = "artem";
      WorkingDirectory = repo;
    };
    script = "python3 tools/budget_push.py";
  };
  systemd.timers.budget-push = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "22:30";
      Persistent = true;
    };
  };

  # The showroom at showroom.pelenitsyn.site: the same hledger-web build on
  # fictional books (showroom-sample.py), for showing the fork to people.
  # It runs with --showroom, which shows everything, the forms included,
  # and saves nothing; the hostname has no Access application, so anyone
  # can look. Like the family's instance it listens on a socket in the
  # finance-web group, which the tunnel is in. The books are made up to
  # today, and made afresh every night, so the month view always has
  # entries; hledger-web reads the file again when it changes.
  systemd.services.hledger-showroom = {
    description = "hledger-web showroom at ${showroomHost}: the fork on fictional books, saving nothing";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    unitConfig.RequiresMountsFor = showroomDir;
    serviceConfig = {
      User = "artem";
      Group = "finance-web";
      UMask = "0007";
      RuntimeDirectory = "hledger-showroom";
      RuntimeDirectoryMode = "0750";
      Environment = [ "XDG_CACHE_HOME=/run/hledger-showroom/cache" ];
      ExecStartPre = [
        "${pkgs.coreutils}/bin/install -d -m 0700 /run/hledger-showroom/cache"
        # the books, if they are not there yet
        "${pkgs.bash}/bin/sh -c 'test -s ${showroomDir}/showroom.journal || ${pkgs.python3}/bin/python3 ${./showroom-sample.py} ${showroomDir}/showroom.journal'"
      ];
      ExecStart = lib.escapeShellArgs [
        "${hledgerWeb}/bin/hledger-web"
        "--serve"
        "--allow=add"
        "--showroom"
        "--socket=${showroomSocket}"
        "--base-url=https://${showroomHost}"
        "--file=${showroomDir}/showroom.journal"
      ];
      Restart = "on-failure";
      RestartSec = 5;

      ProtectHome = "tmpfs";
      BindPaths = [ showroomDir ];
      ProtectSystem = "strict";
      PrivateTmp = true;
      PrivateDevices = true;
      NoNewPrivileges = true;
      RestrictAddressFamilies = [ "AF_UNIX" ];
      IPAddressDeny = "any";
    };
  };
  systemd.services.showroom-sample = {
    description = "Make the showroom's books afresh, up to today";
    unitConfig.RequiresMountsFor = showroomDir;
    serviceConfig = {
      Type = "oneshot";
      User = "artem";
    };
    script = "${pkgs.python3}/bin/python3 ${./showroom-sample.py} ${showroomDir}/showroom.journal";
  };
  systemd.timers.showroom-sample = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "03:15";
      Persistent = true;
    };
  };
}
