set nocompatible
let &rtp = '../../..,' . &rtp
filetype plugin on

let g:tex_flavor = 'latex'

" Simple recursion
silent edit simple.tex
call vimtex#test#assert_equal(
      \ b:vimtex.tex,
      \ fnamemodify('simple.tex', ':p'))
bwipeout!

" Respect the TeX Root directive
silent edit test-texroot/included.tex
call vimtex#test#assert_equal(
      \ fnamemodify(b:vimtex.tex, ':.'),
      \ 'test-texroot/main.tex')
bwipeout!

" This file is included and respects .latexmain
silent edit test-latexmain/included.tex
call vimtex#test#assert_equal(
      \ fnamemodify(b:vimtex.tex, ':.'),
      \ 'test-latexmain/main.tex')
bwipeout!

" This file is included and respects .latexmain
silent new test-latexmain/section1/main.tex
call vimtex#test#assert_equal(
      \ fnamemodify(b:vimtex.tex, ':.'),
      \ 'test-latexmain/main.tex')
bwipeout!

" This file is not included, but should still use .latexmain
silent new test-latexmain/something.tex
call vimtex#test#assert_equal(
      \ fnamemodify(b:vimtex.tex, ':.'),
      \ 'test-latexmain/main.tex')
bwipeout!

quit!
