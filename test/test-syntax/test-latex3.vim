source common.vim

silent edit test-latex3.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texE3Zone', 7, 2))
call assert_true(vimtex#syntax#in('texE3Func', 7, 2))
call assert_true(vimtex#syntax#in('texE3Var', 7, 15))

call vimtex#test#finished()
