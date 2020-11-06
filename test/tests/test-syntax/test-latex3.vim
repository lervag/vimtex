source common.vim

silent edit test-latex3.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texE3Region', 7, 2))
call vimtex#test#assert(vimtex#syntax#in('texE3Func', 7, 2))
call vimtex#test#assert(vimtex#syntax#in('texE3Var', 7, 15))

quit!
