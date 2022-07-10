source common.vim

silent edit test-tabularx.tex

set spell

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texCmdTabularx', 6, 2))
call assert_true(vimtex#syntax#in('texTabularxWidth', 6, 20))
call assert_true(vimtex#syntax#in('texTabularxPreamble', 6, 32))

call assert_true(vimtex#syntax#in('texCmdTabularx', 10, 2))
call assert_true(vimtex#syntax#in('texTabularxWidth', 10, 20))
call assert_true(vimtex#syntax#in('texTabularxOpt', 10, 32))
call assert_true(vimtex#syntax#in('texTabularxPreamble', 10, 37))
call vimtex#test#finished()
