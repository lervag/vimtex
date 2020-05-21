source common.vim

silent edit test-hyperref.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#util#in_syntax('texHyperref', 16, 35))

quit!
