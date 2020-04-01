set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

silent edit test.tex

if empty($INMAKE) | finish | endif

normal! Gkk
silent normal! gf
call vimtex#test#assert_equal('references.bib', expand('%'))

silent normal! 
call vimtex#test#assert_equal('test.tex', expand('%'))

normal! 3k
silent normal! gf
call vimtex#test#assert_equal('include/file.tex', expand('%'))

quit!
