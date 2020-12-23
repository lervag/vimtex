source common.vim

highlight Conceal ctermfg=4 ctermbg=7 guibg=NONE guifg=blue

silent edit test-conceal.tex

vsplit
silent wincmd w
set conceallevel=2

if empty($INMAKE) | finish | endif
quitall!
