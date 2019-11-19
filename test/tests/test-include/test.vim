set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test.tex

if empty($INMAKE) | finish | endif

normal! Gkk
normal! gf
call vimtex#test#assert_equal(expand('%'), 'references.bib')
quit!
