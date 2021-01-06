set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-beamer.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()
call vimtex#test#assert_equal(9, len(s:toc))

call vimtex#test#assert_equal(27, s:toc[8].line)
call vimtex#test#assert_equal('Frame: Finito again', s:toc[8].title)

quit!
