set nocompatible
set runtimepath^=../..
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test-toggle-math.tex

normal! 20G
call vimtex#env#toggle_math()
call assert_equal([
      \ 'World',
      \ '',
      \ '$f(x) = 1 + e^x$',
      \ '',
      \ '\end{document}',
      \], getline(17, 21))

normal! 7G
call vimtex#env#toggle_math()
call assert_equal([
      \ '  This is the proof of Theorem 1. $1+1=2$',
      \ '\end{proof}',
      \], getline(5, 6))

call vimtex#test#finished()
