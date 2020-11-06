source common.vim

silent edit test-ieeetrantools.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texMathRegionEnv', 8, 1))
call vimtex#test#assert(vimtex#syntax#in('texMathRegionEnv', 13, 1))
call vimtex#test#assert(vimtex#syntax#in('texMathRegionEnv', 24, 1))
call vimtex#test#assert(vimtex#syntax#in('texMathRegionEnv', 31, 1))

quit!
