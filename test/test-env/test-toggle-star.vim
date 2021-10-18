set nocompatible
set runtimepath^=../..
filetype plugin on
syntax on

nnoremap q :qall!<cr>

silent edit test-toggle-star.tex

normal! 4G
call vimtex#env#toggle_star()
call assert_equal('\end{document}', getline('$'))

call vimtex#test#finished()
