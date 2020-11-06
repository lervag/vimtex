source common.vim

silent edit test-tikz.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texTikzSemicolon', 66, 61))
call vimtex#test#assert(vimtex#syntax#in('texTikzRegion', 66, 61))
call vimtex#test#assert(vimtex#syntax#in('texCmdAxis', 71, 9))

quit!
