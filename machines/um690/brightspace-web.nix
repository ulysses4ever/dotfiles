# brightspace-web.nix — brightspace-cli's web page, copying a quiz into several
# sections so far, for Artem and Julia at https://brightspace.pelenitsyn.site/,
# behind the Cloudflare Access application that protected grader.pelenitsyn.site.
#
# It acts in Brightspace as whoever signed in. Access signs a token naming them,
# the page checks that token itself against the keys Access publishes, and
# ~/.config/brightspace/web.ini maps the email to a session in keepalive.ini and
# a courses file. A header alone would not do: eight CI runners share this box
# and can reach its port, and anything that can reach it could claim to be
# anyone. Until web.ini names the Access application it refuses everything, so
# the hostname can exist before Access covers it.
#
# web.ini, keepalive.ini and the courses files are hand-edited and never in the
# Nix store: keepalive.ini holds sessions. A change to web.ini takes effect on
# `systemctl restart brightspace-web`; a change to brightspace-cli's checkout
# reaches each command at once and the page itself on the same restart.
{ config, lib, pkgs, ... }:

let
  clone = "/home/artem/edu/brightspace-cli";
  port = 8140;
  # lz4 for re-reading Artem's session out of Firefox's session store, as in
  # brightspace-keepalive.nix; every command the page runs uses this interpreter.
  python = pkgs.python3.withPackages (ps: [ ps.lz4 ]);
in
{
  systemd.services.brightspace-web = {
    description = "Brightspace quiz copying on a page, behind Cloudflare Access";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      # artem's, like course-status.nix and the keep-alive: the sessions, the
      # courses files and the checkout it runs are all his.
      User = "artem";
      Environment = [ "HOME=/home/artem" ];
      ExecStart = "${python}/bin/python3 ${clone}/brightspace-web.py "
        + "--access /home/artem/.config/brightspace/web.ini --port ${toString port} --no-browser";
      Restart = "on-failure";
      RestartSec = 5;

      # The checkouts are live working data; nothing the page runs writes there.
      # Sessions are rewritten under ~/.local/state, which stays writable.
      ReadOnlyPaths = [ "/home/artem/edu" ];
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  # The hostname's DNS record is the tunnel's CNAME, made once with
  # `cloudflared tunnel route dns`; the Access application covering it is set in
  # the Zero Trust dashboard, which is the one part not declared here.
  services.cloudflared.tunnels."2b80d7a7-9b63-4e0f-83b8-fd2601d5fe19".ingress."brightspace.pelenitsyn.site" = {
    service = "http://localhost:${toString port}";
  };
}
