# course-status.nix — course-status.py in a browser, so the report can be read
# from a phone instead of over ssh. Loopback only; the tailnet is the lock.
#
# The report names students and says where their grading stands, and the server
# has no authentication of its own, so it is published on the tailnet and
# nowhere else. Not through cloudflared like the grader: a new Cloudflare
# hostname routes with no Access policy until one is added by hand, and the
# university sinkholes the whole pelenitsyn.site zone anyway, so a public
# hostname would not resolve from campus — which is where this is most wanted.
# The tailnet is already authenticated and already works there.
{ config, lib, pkgs, ... }:

let
  edu = "/home/artem/edu";
  # Beside the grader's 8120 because they are the same family of tooling.
  # Not a course number: this one reports on all three courses.
  port = 8121;
in
{
  systemd.services.course-status = {
    description = "Course status report, in a browser";
    wantedBy = [ "multi-user.target" ];

    # A unit's default PATH is coreutils and systemd, and neither of the two
    # things the report needs is in it. `nix` because course-status.py's
    # shebang is `/usr/bin/env nix-shell`, which is a plain PATH lookup and
    # fails the run outright. `git` because branch() shells out to read which
    # branch each website repo is on — and that one fails *quietly*: the
    # OSError is caught and the column prints `?`, so the header would read
    # `120@?` and look like a fact about the checkout rather than a missing
    # binary. bash is what nix-shell runs the build in.
    path = with pkgs; [ nix git bash coreutils ];

    serviceConfig = {
      # A system unit running as artem, where the grader is a user unit. The
      # grader has to be one because grade.py wraps each submission in
      # `systemd-run --user --scope` and so needs a user manager; nothing here
      # does, and staying out of one means this does not quietly depend on
      # `users.users.artem.linger` being set by a different module to come up
      # at boot. It still runs as artem because the report reads his checkouts
      # and his Dropbox.
      User = "artem";

      ExecStart = "${pkgs.python3}/bin/python3 ${edu}/course-status-serve.py --port ${toString port}";
      Restart = "on-failure";
      RestartSec = 5;

      # course-status.py's shebang is `nix-shell -p`, which resolves <nixpkgs>
      # through NIX_PATH — and a unit is handed none, because NIX_PATH is set
      # in /etc/set-environment for login shells and nothing writes it into
      # /etc/environment.d. This is the one place this module has to differ
      # from the grader, whose shell.nix pins its own nixpkgs and so needs no
      # search path at all.
      #
      # The same spelling the login shell uses, so a report that runs by hand
      # runs the same way here. It resolves through /etc/nix/registry.json,
      # which NixOS pins to this flake's nixpkgs input — the rev the system was
      # built from, already in the system closure, nothing to fetch.
      #
      # `pkgs.path` is the tempting alternative and is worse on this box: it is
      # a *second* copy of the nixpkgs tree under a different hash, unrooted
      # today, so naming it here would pin 466M of store for the life of the
      # generation. Same content, same rev, no benefit.
      Environment = [ "NIX_PATH=nixpkgs=flake:nixpkgs" ];

      # Both trees are live working data and one is a git checkout, so the
      # service is given no way to write to either. course-status-serve.py
      # already runs the script in a scratch directory; this is the half that
      # still holds after someone edits the script.
      ReadOnlyPaths = [ edu "/home/artem/Dropbox" ];

      # nix-shell wants somewhere to scratch and has no reason to share it.
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  # Reset and declaration live together in tailnet-serve.nix; see the header
  # there for why this is an entry rather than a unit of its own.
  um690.tailnetServe.tcp."${toString port}" = "tcp://127.0.0.1:${toString port}";
}
