# vb-update.nix — every day, the Visa Bulletin Tracker (github.com/ulysses4ever/vb)
# checks for a new bulletin and pushes it, which redeploys https://ulysses4ever.github.io/vb/.
#
# The work is tools/update.py in that repo; this module only schedules it and
# publishes what it writes. travel.state.gov answers every automated client with
# Cloudflare's 403 (curl, an undisguised headless Chrome, the Internet Archive's
# crawler), so the cutoffs come from armanckeser/visa-bulletin-data, a dataset that
# caches and parses the bulletin pages. The script refuses to import anything once
# that dataset disagrees with the months already in the repo; on 2026-10-11 all
# 4,900 cells agreed. HANDOFF.md in the repo has the rest.
#
# Daily, because nothing fixes the day: a bulletin comes out some time in the month
# before it applies (October 2026's on 29 September), the dataset has it within six
# hours, and USCIS names its chart days after that. A run with nothing new changes
# nothing and pushes nothing.
#
# Artem hears about it from GitHub, not from here: each push that adds a bulletin or
# a chart makes the repo's Notify workflow open an issue that @-mentions Artem, which
# GitHub emails. This box holds no mail password -- the grader runs students' code
# as artem, so nothing that opens Artem's mailbox belongs in that home directory.
#
# A failure is a journal line, as for brightspace-keepalive: `journalctl -u
# vb-update`. Exit 3 means the dataset had no bulletin for the month yet. The unit
# fails then too, so it shows in `systemctl --failed`, and from the 3rd of a month
# with no bulletin, the same workflow opens an issue about that as well.
{ config, lib, pkgs, ... }:

let
  updateScript = pkgs.writeShellApplication {
    name = "vb-update";
    # tools/update.py needs nothing beyond the standard library.
    runtimeInputs = with pkgs; [ git openssh python3 ];
    text = builtins.readFile ./vb-update.sh;
  };
in
{
  systemd.services.vb-update = {
    description = "Add the new Visa Bulletin to the Visa Bulletin Tracker";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    serviceConfig = {
      Type = "oneshot";

      # A system unit running as artem, for the reason course-status.nix gives. It
      # runs as artem because the commits are Artem's and the deploy key lives in
      # that account: ~/.ssh/vb-deploy, made 2026-10-11 with no passphrase, since
      # nobody is there to type one, and able to write to that one repository only.
      User = "artem";
      Environment = [ "HOME=/home/artem" ];

      # /var/lib/vb-update, created for artem: the script's own clone of the repo.
      StateDirectory = "vb-update";
      ExecStart = "${updateScript}/bin/vb-update";
      NoNewPrivileges = true;
      PrivateTmp = true;
    };
  };

  systemd.timers.vb-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 08:00";
      # Unlike the keep-alive, a run missed while the machine was off is worth
      # catching up: it may be the one with the new bulletin.
      Persistent = true;
    };
  };
}
