set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

set nomore

nnoremap q :qall!<cr>

silent edit test2.tex

if empty($INMAKE) | finish | endif

" Test commands from custom classes
let s:candidates = vimtex#test#completion('\', 'custom')
call vimtex#test#assert(len(s:candidates) > 0)
call vimtex#test#assert_equal(s:candidates[0].word, 'customtest')

quit!
