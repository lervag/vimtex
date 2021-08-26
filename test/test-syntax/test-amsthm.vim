source common.vim

silent edit test-amsthm.tex

set spell

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texCmdThmStyle', 4, 1))
call assert_true(vimtex#syntax#in('texThmStyleArg', 4, 15))
call assert_true(vimtex#syntax#in('texNewthmOptNumberby', 5, 32))
call assert_true(vimtex#syntax#in('texNewthmOptCounter', 6, 19))

call assert_true(vimtex#syntax#in('texProofEnvBgn', 23, 1))
call assert_true(vimtex#syntax#in('texProofEnvOpt', 23, 15))

call assert_true(vimtex#syntax#in('texTheoremEnvBgn', 11, 1))
call assert_true(vimtex#syntax#in('texTheoremEnvBgn', 15, 1))
call assert_true(vimtex#syntax#in('texTheoremEnvBgn', 19, 1))

call assert_true(vimtex#syntax#in('texTheoremEnvOpt', 11, 36))
call assert_true(vimtex#syntax#in('texCmdRefConcealed', 11, 42))
call assert_true(vimtex#syntax#in('texRefConcealedArg', 11, 47))

call vimtex#test#finished()
