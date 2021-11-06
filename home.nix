{ config, pkgs, inputs, ... }:

let
#  emacs-overlay = builtins.fetchTarball "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
#  pkgs = import <nixpkgs> { overlays = [ (import emacs-overlay) ]; };
#  doom-emacs = pkgs.callPackage (builtins.fetchTarball {
#    url = https://github.com/vlaci/nix-doom-emacs/archive/develop.tar.gz;
#  }) {
#    doomPrivateDir = /home/artem/Dropbox/config/doom.d;  # Directory containing your config.el init.el
#    emacsPackages = pkgs.emacsPackagesFor pkgs.emacsPgtkGcc;
#  };
in {


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

  home.packages = with pkgs; [ 
    #doom-emacs
    #pkgs.emacsPgtkGcc
  ];

 # NEOVIM CONFIG
 programs.neovim = {
	  enable = true;
	  extraConfig = ''
      colorscheme deep-space
		  set colorcolumn=90
		  let g:context_nvim_no_redraw = 1
		  set mouse=a
		  set number                              " Turn on line numbers
      set termguicolors
      nnoremap <CR> :noh<CR><CR>              " Hit Enter to clear search highlight

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
      inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"

      " Better tabbing
      vnoremap < <gv
      vnoremap > >gv

      " Better window navigation
      nnoremap <Leader>ww <C-w>w
      nnoremap <Leader>wc <C-w>c
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
      vim-numbertoggle
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
