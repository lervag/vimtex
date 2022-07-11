source common.vim

silent edit test-tabularx.tex

set spell

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texCmdTabularx', 6, 1))
call assert_true(vimtex#syntax#in('texTabularxWidth', 6, 18))
call assert_true(vimtex#syntax#in('texTabularxPreamble', 6, 26))

call assert_true(vimtex#syntax#in('texCmdTabularx', 10, 1))
call assert_true(vimtex#syntax#in('texTabularxWidth', 10, 18))
call assert_true(vimtex#syntax#in('texTabularxOpt', 10, 30))
call assert_true(vimtex#syntax#in('texTabularxPreamble', 10, 35))
call vimtex#test#finished()
