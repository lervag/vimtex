set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

let g:vimtex_toc_config = {
      \ 'name': 'ToC',
      \ 'split_width': 30,
      \}

silent edit main.tex

VimtexTocOpen
wincmd w
vsplit
close

if empty($INMAKE) | finish | endif
call assert_equal(30, winwidth(bufwinid('ToC')))

call vimtex#test#finished()
