source common.vim

silent edit test-breqn.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texRegionMathEnv', 9, 1))

quit!

