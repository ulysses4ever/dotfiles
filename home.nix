{ config, pkgs, inputs, ... }:

{
  # AUTO GENERATED
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "artem";
  home.homeDirectory = "/home/artem";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "21.03";
  # ENF OF AUTO GENERATED

  home.packages = with pkgs; [ ];

  home.file.".ghci".source = ./.ghci;

  # vscode
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
      vscodevim.vim
      yzhang.markdown-all-in-one
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "language-julia";
        publisher = "julialang";
        version = "1.45.1";
        sha256 = "PC+f3mEaiHMYvS5nUmB8e4596Cx2PCBfxKbrE8tFLa4=";
        #         1hp6gjh4xp2m1xlm1jsdzxw9d8frkiidhph6nvl24d0h8z34w49g
      }
    ];
  };

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

  # emacs
  services.emacs.enable = true;
  # remove if controlled by nix-doom-emacs; cf. in flakes.nix
  # programs.emacs.enable = true;
  # programs.emacs.package = pkgs.emacsPgtk;
  # programs.emacs.extraPackages = epkgs: [ epkgs.vterm ];

  # Dropbox
  services.dropbox.enable = true;

  # Sway
  xdg.configFile."sway/config".source = ./sway/config;
  xdg.configFile."sway/machine-dependent".source =
    ./machines/lenovo-p14s/sway/machine-dependent;      # TODO: how to parametrize with
                                                        #       machine name?
  xdg.configFile.waybar.source = ./waybar;

  # bat
  programs.bat = {
    enable = true;
    config.theme = "GitHub";
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
  };

  # Fish
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
      l      = "exa";
      l1     = "exa -1";
      ll     = "exa -l";
      ".."   = "cd ..";
      "..."  = "cd ../..";
      "...." = "cd ../../..";
      b      = "bat";
      c      = "clear";
      g      = "git";
      j      = "julia";
      m      = "make";
      n      = "nix";
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

  # Git
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


 # NEOVIM CONFIG
 programs.neovim = {
	  enable = true;
	  extraConfig = ''
      colorscheme flattened_light
      set colorcolumn=90
      let g:context_nvim_no_redraw = 1
      set mouse=a
      set number                              " Turn on line numbers
      set termguicolors
      nnoremap <ESC> :noh<CR><CR>              " Hit Enter to clear search highlight

      set textwidth=90
      set spell spelllang=en_us
      set complete+=kspell
      set iskeyword-=_
      " let g:doom_one_terminal_colors = v:true

      " Moves according to visible lines, not \n's
      noremap <silent> k gk
      noremap <silent> j gj
      noremap <silent> 0 g0
      noremap <silent> $ g$

      " set leader key
      let g:mapleader = "\<Space>"
      :map <Leader>fs :w<CR>
      :set wrap linebreak nolist

      syntax enable                           " Enables syntax highlighing
      filetype plugin on
      set hidden                              " Required to keep multiple buffers open multiple buffers
      "set nowrap                              " Display long lines as just one line
      set encoding=utf-8                      " The encoding displayed
      set pumheight=10                        " Makes popup menu smaller
      set fileencoding=utf-8                  " The encoding written to file
      set ruler              			            " Show the cursor position all the time
      set cmdheight=2                         " More space for displaying messages
      set splitbelow                          " Horizontal splits will automatically be below
      set splitright                          " Vertical splits will automatically be to the right
      set t_Co=256                            " Support 256 colors
      set conceallevel=0                      " So that I can see `` in markdown files
      set tabstop=2                           " Insert 2 spaces for a tab
      set shiftwidth=2                        " Change the number of space characters inserted for indentation
      set smarttab                            " Makes tabbing smarter will realize you have 2 vs 4
      set expandtab                           " Converts tabs to spaces
      set smartindent                         " Makes indenting smart
      set autoindent                          " Good auto indent
      set laststatus=0                        " Always display the status line
      set cursorline                          " Enable highlighting of the current line
      set showtabline=2                       " Always show tabs
      set noshowmode                          " We don't need to see things like -- INSERT -- anymore
      set nobackup                            " This is recommended by coc
      set nowritebackup                       " This is recommended by coc
      set updatetime=300                      " Faster completion
      set timeoutlen=500                      " By default timeoutlen is 1000 ms
      set formatoptions-=cro                  " Stop newline continution of comments
      set clipboard=unnamedplus               " Copy paste between vim and everything else
      "set autochdir                           " Your working directory will always be the same as your working directory

      au! BufWritePost $MYVIMRC source %      " auto source when writing to init.vm alternatively you can run :source $MYVIMRC

      " You can't stop me
      cmap w!! w !sudo tee %

      " ############################
      "
      " Key mappings
      "
      " ############################

      " Better nav for omnicomplete
      inoremap <expr> <c-j> ("\<C-n>")
      inoremap <expr> <c-k> ("\<C-p>")

      " Use alt + hjkl to resize windows
      nnoremap <M-j>    :resize -2<CR>
      nnoremap <M-k>    :resize +2<CR>
      nnoremap <M-h>    :vertical resize -2<CR>
      nnoremap <M-l>    :vertical resize +2<CR>

      " I hate escape more than anything else
      inoremap jk <Esc>
      inoremap kj <Esc>

      " Easy CAPS
      inoremap <c-u> <ESC>viwUi
      nnoremap <c-u> viwU<Esc>

      " TAB in general mode will move to text buffer
      nnoremap <TAB> :bnext<CR>
      " SHIFT-TAB will go back
      nnoremap <S-TAB> :bprevious<CR>

      " Alternate way to save
      nnoremap <C-s> :w<CR>
      " Alternate way to quit
      nnoremap <C-Q> :wq!<CR>
      " Use control-c instead of escape
      nnoremap <C-c> <Esc>
      " <TAB>: completion.
      " inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"

      " Better tabbing
      vnoremap < <gv
      vnoremap > >gv

      " Better window navigation
      nnoremap <Leader>ws <C-w>s
      nnoremap <Leader>wv <C-w>v

      nnoremap <Leader>ww <C-w>w
      nnoremap <Leader>wc <C-w>d
      nnoremap <Leader>wo <C-w>o

      nnoremap <Leader>wh <C-w>h
      nnoremap <Leader>wj <C-w>j
      nnoremap <Leader>wk <C-w>k
      nnoremap <Leader>wl <C-w>l

      nnoremap <Leader>wH <C-w>H
      nnoremap <Leader>wJ <C-w>J
      nnoremap <Leader>wK <C-w>K
      nnoremap <Leader>wL <C-w>L

      nnoremap <C-h> <C-w>h
      nnoremap <C-j> <C-w>j
      nnoremap <C-k> <C-w>k
      nnoremap <C-l> <C-w>l

      nnoremap <Leader>o o<Esc>^Da
      nnoremap <Leader>O O<Esc>^Da
    '';
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
      coc-nvim coc-git coc-highlight coc-python coc-vimtex coc-yaml coc-html coc-json # auto completion
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
  # END OF NEOVIM CONFIG

}
