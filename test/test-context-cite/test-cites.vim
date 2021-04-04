set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin indent on
syntax enable

set nomore

nnoremap q :qall!<cr>

silent edit test-cites.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert_equal('Hemingway1940',
      \ vimtex#context#get(9, 49).handler.selected)
call vimtex#test#assert_equal('JiM2020',
      \ vimtex#context#get(11, 39).handler.selected)

quit!
