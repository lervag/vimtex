set nocompatible
let &rtp = '../../../..,' . &rtp
filetype plugin indent on
syntax enable

nnoremap q :qall!<cr>

silent edit glossaries.tex

if empty($MAKE) | finish | endif

let s:candidates = vimtex#test#completion('\gls{', '')
call vimtex#test#assert_equal(len(s:candidates), 7)

quit!
