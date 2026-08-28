# Declarative MIME associations.
#
# ~/.config/mimeapps.list used to be mutable state: GTK "Open With" dialogs and
# Wine's winemenubuilder both rewrite it, and nothing ever pruned entries whose
# desktop file had been renamed upstream. That is how application/pdf ended up
# on Wine — the default pointed at evince.desktop (renamed to
# org.gnome.Evince.desktop long ago), xdg-mime silently skips a default it
# cannot resolve, and the next candidate is
# ~/.local/share/applications/mimeinfo.cache, which winemenubuilder owns.
#
# Two things stop that recurring: the file is regenerated from the store on
# every switch, so hand-edits and stray writes cannot survive a rebuild; and
# every desktop file below is checked against the package that ships it at
# build time, so an upstream rename fails `nixos-rebuild` instead of quietly
# demoting the handler.
{ config, lib, pkgs, ... }:

let
  # Each handler names the package it comes from rather than a bare string.
  # That attribution is what makes the build-time check possible.
  apps = [
    { pkg = pkgs.papers; desktop = "org.gnome.Papers.desktop";
      mimes = [ "application/pdf" ];
    }

    { pkg = pkgs.firefox; desktop = "firefox.desktop";
      mimes = [
        "text/html"
        "application/xhtml+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/chrome"
        "x-scheme-handler/about"
        "x-scheme-handler/unknown"
        "application/x-extension-htm"
        "application/x-extension-html"
        "application/x-extension-shtml"
        "application/x-extension-xhtml"
        "application/x-extension-xht"
      ];
    }

    { pkg = pkgs.loupe; desktop = "org.gnome.Loupe.desktop";
      mimes = [
        "image/jpeg" "image/png" "image/gif" "image/webp"
        "image/tiff" "image/bmp" "image/avif" "image/svg+xml"
      ];
    }

    # vlc is X11-only (see packages.nix), and this session is pure Wayland.
    { pkg = pkgs.mpv; desktop = "mpv.desktop";
      mimes = [
        "video/mp4" "video/x-matroska" "video/webm" "video/quicktime"
        "video/x-msvideo" "video/mpeg"
        "audio/mpeg" "audio/flac" "audio/ogg" "audio/x-wav"
      ];
    }

    { pkg = pkgs.gedit; desktop = "org.gnome.gedit.desktop";
      mimes = [ "text/plain" "text/x-makefile" "text/markdown" ];
    }

    { pkg = pkgs.nautilus; desktop = "org.gnome.Nautilus.desktop";
      mimes = [ "inode/directory" ];
    }

    { pkg = pkgs.file-roller; desktop = "org.gnome.FileRoller.desktop";
      mimes = [
        "application/zip" "application/x-tar" "application/gzip"
        "application/x-xz" "application/x-bzip2" "application/x-7z-compressed"
        "application/vnd.rar"
      ];
    }

    { pkg = pkgs.telegram-desktop; desktop = "org.telegram.desktop.desktop";
      mimes = [ "x-scheme-handler/tg" "x-scheme-handler/tonsite" ];
    }

    { pkg = pkgs.transmission_4-gtk; desktop = "transmission-gtk.desktop";
      mimes = [ "x-scheme-handler/magnet" "application/x-bittorrent" ];
    }

    { pkg = pkgs.libreoffice-fresh; desktop = "writer.desktop";
      mimes = [
        "application/rtf"
        "application/msword"
        "application/vnd.oasis.opendocument.text"
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      ];
    }

    { pkg = pkgs.libreoffice-fresh; desktop = "calc.desktop";
      mimes = [
        "text/csv"
        "application/vnd.ms-excel"
        "application/vnd.oasis.opendocument.spreadsheet"
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      ];
    }

    { pkg = pkgs.libreoffice-fresh; desktop = "impress.desktop";
      mimes = [
        "application/vnd.ms-powerpoint"
        "application/vnd.oasis.opendocument.presentation"
        "application/vnd.openxmlformats-officedocument.presentationml.presentation"
      ];
    }
  ];

  claimed = lib.concatMap (a: a.mimes) apps;
  duplicated = lib.unique (lib.filter (m: lib.count (x: x == m) claimed > 1) claimed);

  # listToAttrs silently keeps the first binding, which would hide a genuine
  # disagreement about who owns a type.
  defaults = lib.throwIf (duplicated != [])
    "mime.nix: MIME types claimed by more than one handler: ${toString duplicated}"
    (lib.listToAttrs
      (lib.concatMap (a: map (m: lib.nameValuePair m a.desktop) a.mimes) apps));

  render = sep: lib.concatStringsSep "\n"
    (lib.mapAttrsToList (mime: desktop: "${mime}=${desktop}${sep}") defaults);

  content = ''
    [Default Applications]
    ${render ""}

    [Added Associations]
    ${render ";"}
  '';

in
{
  # The build check below proves a package *ships* a desktop file; it cannot
  # prove the package is installed. Some handlers (papers, loupe) only arrive
  # implicitly via services.desktopManager.gnome, so a change to GNOME's default
  # package set would leave a valid-looking entry pointing at a desktop file
  # that is in no XDG_DATA_DIRS. Owning the packages here closes that gap:
  # declaring a handler is what installs it.
  home.packages = lib.unique (map (a: a.pkg) apps);

  xdg.configFile."mimeapps.list".source =
    pkgs.runCommand "mimeapps.list"
      { inherit content; passAsFile = [ "content" ]; }
      ''
        for entry in ${lib.escapeShellArgs
            (map (a: "${a.pkg}/share/applications/${a.desktop}") apps)}; do
          if [ ! -e "$entry" ]; then
            echo "mime.nix: no such desktop file: $entry" >&2
            exit 1
          fi
        done
        cp "$contentPath" "$out"
      '';
}
