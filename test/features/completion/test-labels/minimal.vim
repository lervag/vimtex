set nocompatible
let &rtp = '../../../../,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit main.tex

if empty($MAKE) | finish | endif

let s:candidates = vimtex#test#completion('\ref{', '')
call vimtex#test#assert_equal(len(s:candidates), 21)

let s:candidates = vimtex#test#completion('\eqref{', '')
call vimtex#test#assert_equal(len(s:candidates), 15)

quit!
