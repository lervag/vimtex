source common.vim

EditConcealed test-fixme.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texCmdTodo', 140, 2))
call assert_true(vimtex#syntax#in('texCmdWarning', 141, 2))
call assert_true(vimtex#syntax#in('texCmdError', 142, 2))
call assert_true(vimtex#syntax#in('texCmdFatal', 143, 2))
call assert_true(vimtex#syntax#in('texFixmeErrorEnvBgn', 144, 10))

call vimtex#test#finished()
