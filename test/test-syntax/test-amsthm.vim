source common.vim

silent edit test-amsthm.tex

set spell

if empty($INMAKE) | finish | endif

call assert_equal(3, len(b:vimtex.syntax.amsthm))

call assert_true(vimtex#syntax#in('texNewthmOptNumberby', 4, 32))
call assert_true(vimtex#syntax#in('texNewthmOptCounter', 5, 19))

call assert_true(vimtex#syntax#in('texNewthmEnvBgn', 10, 1))
call assert_true(vimtex#syntax#in('texNewthmEnvBgn', 14, 1))
call assert_true(vimtex#syntax#in('texNewthmEnvBgn', 18, 1))

call assert_true(vimtex#syntax#in('texNewthmEnvOpt', 10, 36))
call assert_true(vimtex#syntax#in('texCmdRefConcealed', 10, 42))
call assert_true(vimtex#syntax#in('texRefConcealedArg', 10, 47))

quit!
