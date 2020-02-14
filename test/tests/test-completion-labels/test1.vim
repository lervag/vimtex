set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test1.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\ref{', '')
call vimtex#test#assert_equal(len(s:candidates), 21)

let s:candidates = vimtex#test#completion('\eqref{', '')
call vimtex#test#assert_equal(len(s:candidates), 15)

quit!
