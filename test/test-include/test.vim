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

normal! 11G
silent normal! gf
call assert_equal('sub/file2.tex', expand('%'))

silent normal! 
call assert_equal('test.tex', expand('%'))
silent normal! kwgf
call assert_equal('sub/file1.tex', expand('%'))

call assert_equal([
      \ 'test.tex',
      \ 'sub/file1.tex',
      \ 'sub/file2.tex',
      \ 'sub/file3.tex',
      \], b:vimtex.sources)

call vimtex#test#finished()
