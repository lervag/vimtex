set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit main.tex

if empty($MAKE) | finish | endif

let s:parsed = vimtex#parser#toc('main.tex')
call vimtex#test#assert_equal(len(s:parsed), 8)

quit!
