source common.vim

highlight Conceal ctermfg=4 ctermbg=7 guibg=NONE guifg=blue

silent edit test-fontawesome5.tex

vsplit
silent wincmd w
silent windo set scrollbind
set conceallevel=2

if empty($INMAKE) | finish | endif

call vimtex#test#finished()
