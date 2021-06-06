set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test-beamer.tex

if empty($INMAKE) | finish | endif

let s:toc = vimtex#toc#get_entries()
call assert_equal(11, len(s:toc))

call assert_equal('Frame: A title here - Subtitle', s:toc[6].title)
call assert_equal(21, s:toc[6].line)

call assert_equal('Frame: Finito again', s:toc[10].title)
call assert_equal(32, s:toc[10].line)

call vimtex#test#finished()
