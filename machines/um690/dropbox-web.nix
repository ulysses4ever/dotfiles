# dropbox-web.nix — ~/Dropbox at https://dropbox.pelenitsyn.site/, behind the
# Cloudflare Access application "dropbox" (2026-10-31), made mostly for the
# iPhone: browse, download (folders too, as zip), search, edit text files in
# place, upload, make files and folders, move, rename and delete. Everything is
# reachable, the secrets at the top level too; Artem, 2026-10-31: "I need
# secret files as well", "no blocks at all".
#
# The server is dufs (2026-11-01), which replaced File Browser the day after it
# went in: that project was archived on 2026-09-01, with advisories left
# unfixed, and Artem was uneasy running it. dufs is one Rust binary configured
# by flags, with no database. Its page differs from File Browser's in one way
# that matters: an upload replaces a file of the same name without asking.
# Moving and deleting do ask. Its stock page is unreadable on a phone (Artem:
# "font is too small"), opens files in new tabs and shows sizes to a tenth, so
# it gets a stylesheet and a script of ours: dropbox-web.css and dropbox-web.js.
#
# It runs as artem with group syncthing and umask 022, which is how Syncthing
# writes ~/Dropbox: what the page saves is artem:syncthing, 0644 or 0755, like
# everything else there, and Syncthing carries it to the other devices as if it
# had been edited on this box. No ACLs, no new owner.
#
# The undo is on the laptops, not here. Syncthing keeps old copies only of
# changes that arrive from another device, so this box cannot keep them of
# edits made on it; lenovo-x1ca-ap and lenovo-p14s version the folder (their
# syncthing.nix), and keep what an edit, upload or delete here replaced in
# ~/Dropbox/.stversions, once they next sync.
#
# dufs has no login here: it serves whoever reaches its socket. That is the
# tunnel and nobody else, and the tunnel lets a request through only twice over:
#  1. Access admits a.pelenitsyn@gmail.com only (policy "dropbox: Artem").
#  2. cloudflared answers this hostname only for requests carrying that
#     application's Access token (originRequest.access below), so a deleted or
#     loosened application closes the door instead of opening it.
# Like hledger-web in finance.nix, it binds no port, since the eight CI runners
# on this box can reach any TCP port on it: its socket is open to the group
# dropbox-web, whose only member is the tunnel.
#
# The application and the DNS record are the parts not declared here. The
# application and its policy were made through the API with
# ~/.config/cloudflare/dns-token on 2026-10-31, the record by `cloudflared
# tunnel route dns` the same day.
{ config, lib, pkgs, pkgsUnstable, ... }:

let
  tunnel = "2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19";
  host = "dropbox.pelenitsyn.site";
  root = "/home/artem/Dropbox";
  socketDir = "/run/dropbox-web";
  socket = "${socketDir}/web.sock";

  # Not a secret: Access puts it in every token it issues for the application.
  accessAud = "9b874199a5a5942c171ee66716ec5fb73a3ee5008937c80b2c663ee67f091bf8";
  accessTeam = "ulysses4ever";

  # 0.47.0, while 26.05 has 0.45.0 and unstable 0.46.0. Between them: a path
  # ACL bypass through filesystem name aliases closed, symlinks kept inside the
  # served root, panics that could abort the server removed, a unix socket
  # bound only once, and Safari's upload progress fixed. Drop this once
  # unstable has 0.47.0 or later.
  dufs = pkgsUnstable.dufs.overrideAttrs (final: prev:
    assert lib.assertMsg (lib.versionOlder prev.version "0.47.0")
      "unstable's dufs is ${prev.version} now: use it as it is";
    {
      version = "0.47.0";
      src = pkgs.fetchFromGitHub {
        owner = "sigoden";
        repo = "dufs";
        rev = "v${final.version}";
        hash = "sha256-wGRu0E4uAlNtBIZ7C9O0S9VAjQjdn2M0/KV8mqgQWDU=";
      };
      cargoDeps = pkgsUnstable.rustPlatform.fetchCargoVendor {
        inherit (final) src;
        name = "${final.pname}-${final.version}";
        hash = "sha256-DFJjJ8e3EdNC+4AcSXwNPOvJ6rbb7wZR44gmyZzDI2o=";
      };
    });

  # dufs's own page with ours on top (dropbox-web.css and dropbox-web.js say
  # what). --assets serves all its files from here, so they are its own,
  # unchanged but for a viewport that doesn't zoom, our stylesheet appended to
  # its, and our script after its.
  assets = pkgs.runCommand "dufs-${dufs.version}-assets-dropbox" { } ''
    cp -r ${dufs.src}/assets $out
    chmod -R u+w $out
    substituteInPlace $out/index.html --replace-fail \
      '<meta name="viewport" content="width=device-width" />' \
      '<meta name="viewport" content="width=device-width, initial-scale=1" />'
    cat ${./dropbox-web.css} >> $out/index.css
    # dufs sends its assets as immutable for a year, under a path that changes
    # only with its version, so a browser (or Cloudflare) that has the stock
    # stylesheet would keep it. A query dufs ignores but caches don't, from the
    # stylesheet's contents, makes every edit a new URL.
    v=$(sha256sum $out/index.css | cut -c1-16)
    substituteInPlace $out/index.html --replace-fail \
      'href="__ASSETS_PREFIX__index.css"' "href=\"__ASSETS_PREFIX__index.css?v=$v\""
    cp ${./dropbox-web.js} $out/dropbox.js
    v=$(sha256sum $out/dropbox.js | cut -c1-16)
    substituteInPlace $out/index.html --replace-fail \
      '<script src="__ASSETS_PREFIX__index.js"></script>' \
      "<script src=\"__ASSETS_PREFIX__index.js\"></script>
      <script src=\"__ASSETS_PREFIX__dropbox.js?v=$v\"></script>"
  '';

  # dufs makes its socket with the umask's mode, 0755 here, which the tunnel,
  # in the group but not the owner, cannot connect to. A umask of 002 would
  # also make every file it writes group-writable, so the socket alone is
  # opened up, once it exists. The directory still keeps out everyone but
  # artem and the group.
  openSocket = pkgs.writeShellScript "dropbox-web-open-socket" ''
    for _ in $(${pkgs.coreutils}/bin/seq 100); do
      if [ -S ${socket} ]; then exec ${pkgs.coreutils}/bin/chmod 0660 ${socket}; fi
      ${pkgs.coreutils}/bin/sleep 0.1
    done
    echo "dufs made no socket at ${socket}" >&2
    exit 1
  '';
in
{
  # cloudflared can check an Access token itself (originRequest.access), but
  # the module's per-host originRequest has no option for it. Declaring the
  # option here merges it into the module's ingress submodule, and the module
  # writes whatever a host's attribute set holds into the tunnel's config.
  options.services.cloudflared.tunnels = lib.mkOption {
    type = with lib.types; attrsOf (submodule {
      options.ingress = lib.mkOption {
        type = attrsOf (either str (submodule {
          options.originRequest.access = lib.mkOption {
            type = nullOr (submodule {
              options = {
                required = lib.mkOption { type = bool; };
                teamName = lib.mkOption { type = str; };
                audTag = lib.mkOption { type = listOf str; };
              };
            });
            default = null;
            description = "Reject requests without a valid token for this Access application.";
          };
        }));
      };
    });
  };

  config = {
    users.groups.dropbox-web = { };

    # setgid, so the socket dufs makes in it is the group's, not syncthing's,
    # while the files it writes in ~/Dropbox stay syncthing's.
    systemd.tmpfiles.settings.dropbox-web.${socketDir}.d = {
      user = "artem";
      group = "dropbox-web";
      mode = "2750";
    };

    systemd.services.dropbox-web = {
      description = "dufs serving ~/Dropbox, at ${host} behind Cloudflare Access";
      wantedBy = [ "multi-user.target" ];
      after = [ "local-fs.target" "systemd-tmpfiles-setup.service" ];
      unitConfig.RequiresMountsFor = root;

      serviceConfig = {
        User = "artem";
        Group = "syncthing";
        UMask = "0022";
        # A socket left by a crash would make the bind fail.
        ExecStartPre = "${pkgs.coreutils}/bin/rm -f ${socket}";
        ExecStart = lib.escapeShellArgs [
          (lib.getExe dufs)
          "--bind=${socket}"
          # Everything --allow-all grants but --allow-symlink, which would
          # follow links out of ~/Dropbox (there is nothing else to reach in
          # this namespace anyway), and --allow-hash, which nothing here uses.
          "--allow-upload"
          "--allow-delete"
          "--allow-search"
          "--allow-archive"
          "--assets=${assets}"
          root
        ];
        ExecStartPost = openSocket;
        Restart = "on-failure";
        RestartSec = 5;

        ProtectHome = "tmpfs";
        BindPaths = [ root ];
        ProtectSystem = "strict";
        ReadWritePaths = [ socketDir ];
        PrivateTmp = true;
        PrivateDevices = true;
        NoNewPrivileges = true;
        RestrictAddressFamilies = [ "AF_UNIX" ];
        IPAddressDeny = "any";
      };
    };

    systemd.services."cloudflared-tunnel-${tunnel}".serviceConfig.SupplementaryGroups = [ "dropbox-web" ];

    services.cloudflared.tunnels.${tunnel}.ingress.${host} = {
      service = "unix:${socket}";
      originRequest.access = {
        required = true;
        teamName = accessTeam;
        audTag = [ accessAud ];
      };
    };
  };
}
