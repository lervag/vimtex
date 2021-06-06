source common.vim

silent edit test-tcolorbox.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texTCBZone', 19, 1))

call vimtex#test#finished()
