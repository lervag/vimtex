source common.vim

silent edit test-conceal.tex

vsplit
set conceallevel=2

if empty($INMAKE) | finish | endif
quitall!
