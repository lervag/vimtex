source common.vim

silent edit test-tabularx.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texTabularCol', 7, 17))
call vimtex#test#assert(vimtex#syntax#in('texTabularMathdelim', 7, 24))

quit!
