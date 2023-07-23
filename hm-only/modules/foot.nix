{ config, lib, pkgs, ... }:

{
  # foot
  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {
      main = {
        shell = "fish";
        font = "monospace:size=10";
      };
      scrollback = {
        lines = "50000";
      };
      cursor = {
        # color = "002b36 93a1a1"; # Solarized dark
        color = "fdf6e3 586e75"; # Solarized light
      };
      colors = {
        alpha = "0.9";

        ## Themes

        # Solarized dark
       # foreground = "839496";
       # background = "002B36";
       # regular0 = "171421";
       # regular1 = "C01C28";
       # regular2 = "26A269";
       # regular3 = "A2734C";
       # regular4 = "12488B";
       # regular5 = "A347BA";
       # regular6 = "2AA1B3";
       # regular7 = "D0CFCC";
       # bright0  = "5E5C64";
       # bright1  = "F66151";
       # bright2  = "33D17A";
       # bright3  = "E9AD0C";
       # bright4  = "2A7BDE";
       # bright5  = "C061CB";
       # bright6  = "33C7DE";
       # bright7  = "FFFFFF";

        # Solarized light
        background = "fdf6e3";
        foreground = "657b83";
        regular0 = "eee8d5";
        regular1 = "dc322f";
        regular2 = "859900";
        regular3 = "b58900";
        regular4 = "268bd2";
        regular5 = "d33682";
        regular6 = "2aa198";
        regular7 = "073642";
        bright0 = "cb4b16";
        bright1 = "fdf6e3";
        bright2 = "93a1a1";
        bright3 = "839496";
        bright4 = "657b83";
        bright5 = "6c71c4";
        bright6 = "586e75";
        bright7 = "002b36";
      };
    };
  };
}
