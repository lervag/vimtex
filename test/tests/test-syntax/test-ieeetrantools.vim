source common.vim

silent edit test-ieeetrantools.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texRegionMathEnv', 8, 1))
call vimtex#test#assert(vimtex#syntax#in('texRegionMathEnv', 13, 1))
call vimtex#test#assert(vimtex#syntax#in('texRegionMathEnv', 24, 1))
call vimtex#test#assert(vimtex#syntax#in('texRegionMathEnv', 31, 1))

quit!
