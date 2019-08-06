set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

let g:vimtex_view_automatic = 0

if has('nvim')
  let g:vimtex_compiler_progname = 'nvr'
endif

silent edit minimal.tex

" Functions for profiling
" call vimtex#profile#file('some_file')
" call vimtex#profile#filter([
"       \ 'FUNCTIONS SORTED ON SELF',
"       \ 'FUNCTIONS SORTED ON TOTAL',
"       \ 'FUNCTION  vimtex#fold#level',
"       \])
" call vimtex#profile#print()
" call vimtex#profile#open()
