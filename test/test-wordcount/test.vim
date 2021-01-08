set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit minimal.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert_equal(50, vimtex#misc#wordcount())

call vimtex#test#assert_equal(25, vimtex#misc#wordcount({'range': [4, 5]}))

quit!
