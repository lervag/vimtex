set nocompatible
set runtimepath^=../..
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test-toggle-lists.tex

normal! 5G
call vimtex#env#toggle()
call assert_equal('\begin{enumerate}', getline(4))
call assert_equal('\end{enumerate}', getline(7))

call vimtex#test#finished()
