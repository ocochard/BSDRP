" BSD Router Project vimrc file.

" don't use vi compatible mode
set nocompatible

"Syntax color
syntax on

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" do not keep a backup file, use versions instead
set nobackup

" keep 50 lines of command line history
set history=50

" show the cursor position all the time
set ruler

" max size of a line
set textwidth=80

" display incomplete commands
set showcmd

" use 4 spaces instead of tabs
set tabstop=4
set shiftwidth=4
set expandtab "replace tab by space
set softtabstop=4

set nowrapscan
set paste

" Disable mouse
set mouse-=a

" always show ^M in DOS files
set fileformats=unix

" always show line and col number and the current command, set title
set title titlestring=vim\ %f

" caseinsensitive incremental search
set ignorecase
set incsearch

" Show matching brackets
set showmatch

" disable any autoindenting which could mess with your mouse pastes (and your head)
" (not useing 'set paste' here to keep fancy stuff like tab completion working)
set nocindent
set nosmartindent
set noautoindent
set indentexpr=
filetype indent off
filetype plugin indent off

" Default Shell
set shell=/bin/sh

" disable the use of swap file
set noswapfile

