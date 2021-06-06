source common.vim

silent edit test-tikz.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texTikzSemicolon', 66, 61))
call assert_true(vimtex#syntax#in('texTikzZone', 66, 61))
call assert_true(vimtex#syntax#in('texCmdAxis', 71, 9))

call vimtex#test#finished()
