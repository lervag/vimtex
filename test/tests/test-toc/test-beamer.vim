set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-beamer.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()
call vimtex#test#assert_equal(8, len(s:toc))

quit!
