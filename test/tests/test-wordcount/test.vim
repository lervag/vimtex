set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit minimal.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert_equal(vimtex#misc#wordcount(), 50)

quit!
