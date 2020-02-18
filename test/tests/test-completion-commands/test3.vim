set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit test3.tex

if empty($INMAKE) | finish | endif

" Test commands from custom classes for speed
let s:candidates = vimtex#test#completion('\', '')
call vimtex#test#assert(len(s:candidates) > 0)

quit!
