source common.vim

silent edit test-tcolorbox.tex

if empty($INMAKE) | finish | endif

call vimtex#test#assert(vimtex#syntax#in('texTCBZone', 19, 1))

quit!
