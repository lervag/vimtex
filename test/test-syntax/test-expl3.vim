source common.vim

silent edit test-expl3.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(!vimtex#syntax#in('texGroupError', 29, 1))

quit!
