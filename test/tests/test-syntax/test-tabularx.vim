source common.vim

silent edit test-tabularx.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texTabularCol', 10, 17))
call vimtex#test#assert(vimtex#syntax#in('texTabularMathdelim', 10, 24))

quit!
