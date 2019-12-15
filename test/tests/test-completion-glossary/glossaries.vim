set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit glossaries.tex

if empty($INMAKE) | finish | endif

let s:candidates = vimtex#test#completion('\gls{', '')
call vimtex#test#assert_equal(len(s:candidates), 7)

" Allow completion for custom keys (#1489)
let s:candidates = vimtex#test#completion('\Glsentrymaccusative{', '')
call vimtex#test#assert_equal(len(s:candidates), 7)

quit!
