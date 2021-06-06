set nocompatible
let &rtp = '../..,' . &rtp
filetype plugin on

nnoremap q :qall!<cr>

set nomore

silent edit test.tex

if empty($INMAKE) | finish | endif

normal! Gkk
silent normal! gf
call assert_equal('references.bib', expand('%'))

silent normal! 
call assert_equal('test.tex', expand('%'))

normal! 3k
silent normal! gf
call assert_equal('sub/file2.tex', expand('%'))

silent normal! kw
call assert_equal('test.tex', expand('%'))
normal! gf
call assert_equal('sub/file1.tex', expand('%'))

call vimtex#test#finished()
