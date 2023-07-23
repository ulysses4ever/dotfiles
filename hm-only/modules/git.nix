{ config, lib, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName  = "Artem Pelenitsyn";
    userEmail = "a.pelenitsyn@gmail.com";
    signing.key = "A31C1BFA09B1F47D";
    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
        theme = "GitHub";
      };
    };
    extraConfig = {
      branch = { autosetuprebase = "always"; };
      core   = { editor = "vi"; };
      merge  = { conflictstyle = "diff3"; };
      diff   = { colorMoved = "default"; }; github = { user = "ulysses4ever"; };
      init   = { defaultBranch = "main"; };
    };
    aliases = {
      aa   = "add --all";
      cam  = "commit -am";
      cn   = "commit --amend";
      cnn  = "commit --amend --no-edit";
      cann = "commit -a --amend --no-edit";
      c    = "clone";
      co   = "checkout";
      df   = "diff -w --color-words=.";
      hist = "log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short";
      l    = "log";
      l1   = "log --oneline";
      lgb  = "log --graph --pretty=oneline --abbrev-commit --branches";
      ph   = "push";
      pl   = "pull";
      rh   = "reset --hard";
      s    = "status";
      st   = "stash";
      stp  = "stash pop";
      sta  = "stash apply";
    };
  };
}
