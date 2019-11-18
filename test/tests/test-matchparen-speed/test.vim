set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on
syntax on

set nomore
set noswapfile

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'

" let g:vimtex_matchparen_enabled = 0
" let g:vimtex_delim_stopline = 1000
" let g:vimtex_delim_timeout = 100
" let g:vimtex_delim_insert_timeout = 50

silent edit test.tex

" profile start prof.log
" profile func *

normal! Go}

call feedkeys(":qa!\<cr>")
