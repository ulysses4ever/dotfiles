{ config, pkgs, lib, ... }:

# =============================================================================
# Commonwealth University of Pennsylvania VPN  (Cisco AnyConnect / SAML+Duo)
# =============================================================================
#
#   Gateway:  vpn.commonwealthu.edu
#   Protocol: Cisco AnyConnect over SSL/DTLS
#   Auth:     SAML SSO with Duo MFA (there is no shared secret / password field)
#   Group:    Faculty/Staff
#
#   Vendor KB: https://kb.itd.commonwealthu.edu/books/network/page/connecting-to-vpn
#   (the KB only documents the vendor Cisco Secure Client GUI on Win/macOS;
#    the setup below is the Linux/NixOS equivalent, worked out by trial.)
#
# To connect:
#     nmcli con up "CommonwealthU VPN"
#   → nm-openconnect-auth-dialog pops up (workspace where sway put it)
#   → click Login, an embedded WebKit view shows the SAML page, do Duo push
#   → tunnel comes up on tun0.  Session ticket is valid ~7 days.
#   Split-tunnel: only CU subnets route through tun0 (by design — the server
#   explicitly refuses to be used from on-campus networks).
#
# -----------------------------------------------------------------------------
# WHY THIS MODULE LOOKS THE WAY IT DOES  —  the road not taken
# -----------------------------------------------------------------------------
#
# The obvious first attempts all failed for non-obvious reasons.  Documenting
# them here so nobody (including future-me) re-does the same detective work.
#
# 1. `sudo openconnect --user=... --authgroup=Faculty/Staff vpn.commonwealthu.edu`
#    → server returns an <auth-request> with <sso-v2-login>…</sso-v2-login>,
#      openconnect prints "No SSO handler" and exits.
#    Root cause: nixpkgs builds `openconnect` without a webview library
#      (no libwebkit2gtk linked in), so libopenconnect has no way to render
#      the SAML page.  The CLI can NEGOTIATE SSO but cannot COMPLETE it.
#
# 2. `openconnect --external-browser=firefox …`
#    → same "No SSO handler" error.
#    Root cause: the server offers two SSO methods in its <capabilities>:
#      `single-sign-on-v2` (in-client webview) and `single-sign-on-external-browser`
#      (open a real browser, callback via localhost).  Even though the client
#      advertises support for both, THIS server always chooses sso-v2 and never
#      hands out an `sso-external-browser-login` element.  openconnect's
#      `--external-browser` handler only activates for the second method, so
#      it stays dormant.  There is no client-side flag to force the choice.
#
# 3. `nix run github:vlaci/openconnect-sso` (the well-known Python+Qt wrapper
#    people usually reach for on Linux).
#    → flake evaluation fails with "infinite recursion" (nixpkgs input pinned
#      to 2021-05), then with "poetry2nix is now maintained out-of-tree" after
#      overriding to a modern nixpkgs.  The upstream flake has bit-rotted.
#    Could be salvaged with a fresh packaging effort, but the NM route below
#    turned out to be simpler and needs no third-party code.
#
# 4. The NetworkManager plugin route (what we ended up with).
#    The `NetworkManager-openconnect` plugin ships a helper binary
#    `nm-openconnect-auth-dialog` that IS linked against `libwebkit2gtk-4.1`
#    and IS built to call `openconnect_set_webview_callback()` on the shared
#    libopenconnect.  So when NM invokes libopenconnect via this helper,
#    the SSO handler exists and the SAML page is rendered inside the dialog.
#    The plain CLI can't do this because it doesn't link webkit; the same
#    library, invoked from the dialog, can — that's the whole trick.
#
#    Sub-stumbling-points once on this route:
#
#    a) First `nmcli con up` attempts timed out with NM logging:
#         "secrets: failed to request VPN secrets: No agents were available"
#       There was no secret agent registered on the session bus.  `nmcli`
#       itself only implements a tty-based agent that can't launch a WebKit
#       dialog.  Fix: run `nm-applet` on every session (see sway/config).
#
#    b) With nm-applet running, the dialog would flash and clear its fields
#       every time we clicked Login — never opening the SAML view.  Root
#       cause: we had set `authtype=password` on the connection, which puts
#       the dialog into a "collect username & password, then submit" mode.
#       For SSO you must NOT set authtype; leave it unset and the dialog
#       will hand control to the WebKit view instead.
#
#    c) With authtype removed the dialog still refused to open the SAML view
#       for the first couple of attempts — the server treated the connection
#       as though SSO wasn't supported.  Adding `useragent="AnyConnect
#       Linux_64 5.1.4.74"` and `reported_os=win` to vpn.data fixed it:
#       the Cisco ASA appears to gate its full SAML flow on the client
#       pretending to be a "real" AnyConnect release.  With openconnect's
#       default UA (`Open AnyConnect VPN Agent …`) the server serves a
#       degraded auth path.
#
# 5. nm-applet tray icon showed as a solid white rectangle in waybar.
#    Diagnosis: the SNI (StatusNotifierItem) `IconName` property emitted by
#    nm-applet is e.g. `nm-signal-75-secure` — with NO `-symbolic` suffix.
#    nixpkgs' `networkmanagerapplet` only installs the `-symbolic.svg`
#    variants under `share/icons/hicolor/scalable/apps/`, so an exact-name
#    lookup by waybar/GTK misses and falls back to a blank glyph.
#    Fix: the `nmAppletIconsCompat` derivation below creates non-symbolic
#    filename aliases pointing at the symbolic SVGs; NixOS activation then
#    regenerates the hicolor icon cache and the lookup succeeds.  This
#    should really be patched upstream in nixpkgs.
#
# -----------------------------------------------------------------------------

let
  # See stumbling-point 5 above.
  #
  # Every  nm-*-symbolic.svg  in networkmanagerapplet gets a companion
  # symlink  nm-*.svg  → nm-*-symbolic.svg  in this derivation's output.
  # The output is added to systemPackages so its icons merge into
  # /run/current-system/sw/share/icons/hicolor/scalable/apps/ , and
  # NixOS's activation script regenerates hicolor's icon-theme.cache
  # (`strings icon-theme.cache | grep nm-signal-75-secure` confirms it).
  #
  # No new content is copied; these are just filename aliases, so the
  # closure impact is a handful of symlinks.
  nmAppletIconsCompat = pkgs.runCommandLocal "nm-applet-icons-compat" { } ''
    mkdir -p $out/share/icons/hicolor/scalable/apps
    for f in ${pkgs.networkmanagerapplet}/share/icons/hicolor/scalable/apps/*-symbolic.svg; do
      name=$(basename "$f" -symbolic.svg)
      ln -s "$f" "$out/share/icons/hicolor/scalable/apps/$name.svg"
    done
  '';
in
{
  environment.systemPackages = with pkgs; [
    # openconnect CLI is included even though we can't use it standalone
    # for THIS VPN (see stumbling-points 1–2) — it's still the underlying
    # library used by the NM plugin, and it's handy for probing other
    # AnyConnect-compatible gateways.
    openconnect

    # nm-applet plays two roles: (i) the tray icon in waybar, and
    # (ii) the DBus SecretAgent NetworkManager talks to for interactive
    # VPN authentication — this is the thing that pops up the WebKit
    # dialog for SAML.  Without it running, `nmcli con up` on any VPN
    # times out with "No agents were available".  Started from sway/config.
    networkmanagerapplet

    # Icon-name aliases so waybar can render nm-applet's tray icon.
    nmAppletIconsCompat
  ];

  # The NM plugin that provides service-type
  # `org.freedesktop.NetworkManager.openconnect` and, crucially, the
  # WebKit-linked auth dialog.  This is what makes SAML SSO work at all
  # on nixpkgs — see stumbling-point 4.
  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];

  # Declarative NetworkManager profile.  Rendered on activation to
  # /var/run/NetworkManager/system-connections/CommonwealthU-VPN.nmconnection
  # (declarative profiles live under /var/run, not /etc, so they can be
  # regenerated cleanly on each rebuild).
  networking.networkmanager.ensureProfiles.profiles."CommonwealthU-VPN" = {
    connection = {
      id = "CommonwealthU VPN";
      type = "vpn";
      # Manual connect only.  Autoconnect would try to bring the VPN up on
      # every boot even when we're on-campus, where it's explicitly not
      # supported and would break the network.
      autoconnect = false;
      # Empty permissions = system-wide (any user in the `networkmanager`
      # group can toggle it).
      permissions = "";
    };
    vpn = {
      service-type = "org.freedesktop.NetworkManager.openconnect";
      protocol = "anyconnect";
      gateway = "vpn.commonwealthu.edu";

      # DO NOT add  authtype = "password";  here.
      # See stumbling-point 4b: setting authtype forces the dialog into a
      # local-credential-collection mode and it never hands off to WebKit.
      # Leaving it unset lets openconnect's SSO negotiation drive the UI.

      # See stumbling-point 4c: these two together convince the ASA to
      # serve the full SAML flow instead of a degraded fallback.
      useragent = "AnyConnect Linux_64 5.1.4.74";
      reported_os = "win";

      # NOTE: no `authgroup` set here.  The server pre-selects Faculty/Staff
      # for our SAML identity; the dialog also lets the user override it
      # from a dropdown if that ever changes.
    };
    ipv4.method = "auto";
    ipv6.method = "auto";
  };
}
