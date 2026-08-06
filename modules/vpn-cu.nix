{ config, pkgs, lib, ... }:

let
  # nm-applet in nixpkgs installs its tray icons only as `-symbolic.svg` variants,
  # but its SNI IconName property omits the `-symbolic` suffix. Waybar's tray lookup
  # then can't resolve the icon and shows a blank rectangle.
  # This overlay creates non-symbolic name aliases so the SNI lookup succeeds.
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
    openconnect            # Cisco AnyConnect / Secure Client compatible CLI
    networkmanagerapplet   # nm-applet: NM secret agent + WebKit-backed SAML auth dialog
    nmAppletIconsCompat
  ];

  networking.networkmanager.plugins = [ pkgs.networkmanager-openconnect ];

  # Declarative NM VPN profile for Commonwealth University of Pennsylvania.
  # Auth is SAML+Duo; nm-openconnect-auth-dialog opens an embedded WebKit browser
  # on connect and the tunnel comes up when the user finishes the Duo push.
  networking.networkmanager.ensureProfiles.profiles."CommonwealthU-VPN" = {
    connection = {
      id = "CommonwealthU VPN";
      type = "vpn";
      autoconnect = false;
      permissions = "";
    };
    vpn = {
      service-type = "org.freedesktop.NetworkManager.openconnect";
      protocol = "anyconnect";
      gateway = "vpn.commonwealthu.edu";
      # Some Cisco ASA deployments only offer SSO to "real" AnyConnect clients;
      # spoofing UA+OS is what unblocks the SAML flow here.
      useragent = "AnyConnect Linux_64 5.1.4.74";
      reported_os = "win";
    };
    ipv4.method = "auto";
    ipv6.method = "auto";
  };
}
