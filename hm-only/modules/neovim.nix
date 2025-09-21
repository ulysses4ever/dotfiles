{ config, lib, pkgs, ... }:

{
 home.packages = [ pkgs.nodejs-slim ]; # somehow, nvim is complaining when it doesn't see node
 programs.neovim = {
	  enable = true;
	  extraConfig = builtins.readFile ./neovim.rc;
	  plugins = with pkgs.vimPlugins; let
      doom-one = pkgs.vimUtils.buildVimPlugin {
        name = "doom-one";
        src = pkgs.fetchFromGitHub {
          owner = "romgrk";
          repo = "doom-one.vim";
          rev = "1f37d52bbafb54e1b0f82dae5fb6d36eef57435f";
          sha256 = "1wabbh85pb48mvsxr6f3b0rpim73sqa5nnq0glh285w9hrmapngc";
        };
      };
       context-vim = pkgs.vimUtils.buildVimPlugin {
        name = "context-vim";
        src = pkgs.fetchFromGitHub {
          owner = "wellle";
          repo = "context.vim";
          rev = "e38496f1eb5bb52b1022e5c1f694e9be61c3714c";
          sha256 = "1iy614py9qz4rwk9p4pr1ci0m1lvxil0xiv3ymqzhqrw5l55n346";
        };
      };
    in [
      #context-vim
      editorconfig-vim
      awesome-vim-colorschemes
      #doom-one
      vim-surround vim-repeat
      vim-easymotion
      vim-sneak
      #vim-numbertoggle
      coc-nvim coc-git coc-highlight coc-vimtex coc-yaml coc-html coc-json # auto completion
      vim-airline
      vim-nix
      vimtex
      julia-vim
      csv-vim
    ]; # Only loaded if programs.neovim.extraConfig is set
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
  };
}
