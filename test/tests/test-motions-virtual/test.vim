set nocompatible
let &rtp = '../../..,' . &rtp
let &rtp .= ',../../../after'
filetype plugin indent on
syntax on

set nomore

nnoremap q :qall!<cr>

let g:tex_flavor = 'latex'
" let g:vimtex_matchparen_enabled = 0

silent edit test.tex

if empty($INMAKE) | finish | endif

" Test for #1537
call feedkeys("\<c-v>j$d", 'tm')
call feedkeys(":wq! test.out\<cr>", 't')
