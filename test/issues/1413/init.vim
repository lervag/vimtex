set nocompatible
set packpath+=.
set runtimepath+=.
filetype plugin indent on
syntax enable

packadd vimtex

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

let g:vimtex_view_automatic = 0

if has('nvim')
  let g:vimtex_compiler_progname = 'nvr'
endif

edit minimal.tex
