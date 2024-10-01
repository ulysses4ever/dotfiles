{ config, lib, pkgs, ... }:

{

  programs.fish = {
    enable = true;
    shellInit = ''
      starship init fish | source
      fish_vi_key_bindings
      set GPG_TTY (tty)
      gpg-connect-agent updatestartuptty /bye >/dev/null
    '';
    shellAliases = {
      mkdir  = "mkdir -p";
      l      = "eza";
      l1     = "eza -1";
      ll     = "eza -l";
      ".."   = "cd ..";
      "..."  = "cd ../..";
      "...." = "cd ../../..";
      b      = "bat";
      c      = "clear";
      g      = "git";
      j      = "julia";
      m      = "make";
      p      = "ssh prl-julia";
      t      = "tmux";
    };
    functions = {
      fish_greeting = {
        description = "Greeting to show when starting a fish shell";
        body = "";
      };
      mkdcd = {
        description = "Make a directory tree and enter it";
        body = "mkdir -p $argv[1]; and cd $argv[1]";
      };
      cd = {
        description = "cd and ll (list files)";
        body = ''
            if count $argv > /dev/null
              builtin cd "$argv"; and ll
            else
              builtin cd ~
            end
        '';
      };
      cdc = {
        description = "cd and clear screen";
        body = "cd \"$argv\"; and clear";
      };
    };
  };
}
