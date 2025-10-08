set nocompatible
set runtimepath^=../..
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test-toggle-math.tex

normal! 24G
call vimtex#env#toggle_math()
call assert_equal([
      \ 'World',
      \ '',
      \ '$f(x) = 1 + e^x$',
      \ '',
      \ '\end{document}',
      \], getline(21, 25))

normal! 7G
call vimtex#env#toggle_math()
call assert_equal([
      \ '  This is the proof of Theorem 1. $1+1=2$',
      \ '\end{proof}',
      \], getline(5, 6))

let g:vimtex_env_toggle_math_map = {
      \ 'equation': 'align',
      \}

normal! 11G
call vimtex#env#toggle_math()
call assert_equal([
      \ '\begin{align}',
      \ '  1+1=2',
      \ '\end{align}',
      \], getline(10, 12))

normal! 15G
call vimtex#env#toggle_math()
call assert_equal([
      \ '\begin{align*}',
      \ '  1+1=2',
      \ '\end{align*}',
      \], getline(14, 16))

call vimtex#test#finished()
