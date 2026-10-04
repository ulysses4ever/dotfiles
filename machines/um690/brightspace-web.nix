# brightspace-web.nix — brightspace-cli's web page: making a quiz, in its course or
# in an empty shell to copy into several sections, copying it, and each course's
# quiz defaults, for Artem and Julia at https://brightspace.pelenitsyn.site/,
# behind its own Cloudflare Access application, "brightspace web" (2026-10-04).
#
# It acts in Brightspace as one of the sessions in keepalive.ini. Access signs a
# token naming whoever signed in, the page checks that token itself against the
# keys Access publishes, and ~/.config/brightspace/web.ini gives each email the
# sessions it may pick from, each with its courses file and quiz defaults. A
# header alone would not do: eight CI runners share this box and can reach its
# port, and anything that can reach it could claim to be anyone. Until web.ini
# names the Access application it refuses everything.
#
# web.ini, keepalive.ini, the courses files and the quiz defaults are never in
# the Nix store: keepalive.ini holds sessions. The page writes only the quiz
# defaults, under ~/.config, when a course's are saved. A change to web.ini takes
# effect on `systemctl restart brightspace-web`; a change to brightspace-cli's
# checkout reaches each command at once and the page itself on the same restart.
{ config, lib, pkgs, ... }:

let
  clone = "/home/artem/edu/brightspace-cli";
  port = 8140;
  # lz4 for re-reading Artem's session out of Firefox's session store, as in
  # brightspace-keepalive.nix, and PyYAML for a quiz's YAML file, which the page
  # makes a quiz from with setup-quiz; every command it runs uses this interpreter.
  python = pkgs.python3.withPackages (ps: [ ps.lz4 ps.pyyaml ]);
in
{
  systemd.services.brightspace-web = {
    description = "Brightspace quizzes on a page, behind Cloudflare Access";
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
