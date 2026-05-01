" ~/.vimrc — Sensible defaults for homelab work

" General
set nocompatible            " Use Vim defaults
syntax on                   " Syntax highlighting
filetype plugin indent on   " Detect filetype, load plugins + indent
set encoding=utf-8          " UTF-8 everywhere
set backspace=indent,eol,start

" Indentation
set tabstop=4               " Tab = 4 spaces
set shiftwidth=4            " Indent = 4 spaces
set softtabstop=4
set expandtab               " Tabs → spaces
set autoindent
set smartindent

" YAML override (2-space indent)
autocmd FileType yaml setlocal ts=2 sw=2 sts=2 expandtab
autocmd FileType yml setlocal ts=2 sw=2 sts=2 expandtab

" UI
set number                  " Line numbers
set relativenumber          " Relative line numbers
set cursorline              " Highlight current line
set ruler                   " Show cursor position
set showcmd                 " Show partial commands
set showmatch               " Highlight matching brackets
set wildmenu                " Tab completion menu
set wildmode=longest:full,full
set laststatus=2            " Always show status line
set scrolloff=5             " Keep 5 lines above/below cursor

" Search
set incsearch               " Search as you type
set hlsearch                " Highlight matches
set ignorecase              " Case-insensitive search...
set smartcase               " ...unless uppercase is used

" Clear search highlight with Esc
nnoremap <Esc> :nohlsearch<CR><Esc>

" Files
set nobackup                " Don't litter backup files
set noswapfile              " No swap files
set autoread                " Reload changed files automatically
set hidden                  " Allow unsaved buffers in background

" Clipboard
set clipboard=unnamedplus   " Use system clipboard

" Whitespace visibility (toggle with :set list!)
set listchars=tab:▸\ ,trail:·,eol:¬
