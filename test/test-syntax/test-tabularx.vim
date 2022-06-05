source common.vim

silent edit test-tabularx.tex

set spell

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texCmdTabularx', 6, 2))
call assert_true(vimtex#syntax#in('texTabularxWidth', 6, 20))
call assert_true(vimtex#syntax#in('texTabularxArg', 6, 32))

call assert_true(vimtex#syntax#in('texCmdTabularx', 11, 2))
call assert_true(vimtex#syntax#in('texTabularxOpt', 11, 20))
call assert_true(vimtex#syntax#in('texTabularxWidth', 11, 26))
call assert_true(vimtex#syntax#in('texTabularxArg', 11, 38))
call vimtex#test#finished()
