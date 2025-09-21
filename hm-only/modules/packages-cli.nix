{ pkgs, ... }:

{
  home.packages = with pkgs; [
      # Command-Line Tools
      wget mc file bc
      patchelf
      lshw
      lynx
      openvpn openssl
      parted
      # sudo -- this causes permissions problems on non-nixos setups;
      #         add to systemPackages instead
      xorg.xbacklight
      zip unzip
      zlib zlib.dev
      which
      pciutils
      htop
      gnupg
      inetutils
      killall
      imagemagick
      cachix
      comma # run soft w/o install
      findutils.locate # plocate # locate

      # Text
      aspell
      aspellDicts.en enchant # helps with spell-checking in e.g. gEdit

      # Development basics
      git
      binutils gnumake gdb

      # Temperature (and other) diagnostics
      lm_sensors hddtemp

      # Modern Unix
      fd eza procs tldr bat
      silver-searcher ripgrep
      fish
      starship
      kitty
      neofetch # beautiful splash screen for terminal
      tmux # the ultimate terminal manager
  ];
}
