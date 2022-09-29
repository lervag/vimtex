set nocompatible
set runtimepath^=../..
filetype plugin indent on
syntax on

set shiftwidth=2
set expandtab

nnoremap q :qall!<cr>

silent edit test-surround.tex

execute "normal 13G\<plug>(vimtex-env-surround-operator)3jnumbers\<cr>"
call assert_equal([
      \ '\begin{numbers}',
      \ '  one',
      \ '  two',
      \ '  three',
      \ '  four',
      \ '\end{numbers}'
      \], getline(13, 18))

call vimtex#env#surround(9, 10, 'verbatim')
call assert_equal([
      \ '\begin{quote}',
      \ '  \begin{verbatim}',
      \ '    This is wrongly indented.',
      \ '    Two lines.',
      \ '  \end{verbatim}',
      \ '\end{quote}'
      \], getline(8, 13))

call vimtex#env#surround(4, 6, 'test')
call assert_equal([
      \ '\begin{test}',
      \ '  Hello World!',
      \ '',
      \ '  Hello Moon!',
      \ '\end{test}',
      \], getline(4, 8))

call vimtex#test#finished()
