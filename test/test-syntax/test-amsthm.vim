source common.vim

EditConcealed test-amsthm.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texCmdThmStyle', 4, 1))
call assert_true(vimtex#syntax#in('texThmStyleArg', 4, 15))
call assert_true(vimtex#syntax#in('texNewthmOptNumberby', 5, 32))
call assert_true(vimtex#syntax#in('texNewthmOptCounter', 6, 19))

call assert_true(vimtex#syntax#in('texProofEnvBgn', 25, 1))
call assert_true(vimtex#syntax#in('texProofEnvOpt', 25, 15))

call assert_true(vimtex#syntax#in('texTheoremEnvBgn', 13, 1))
call assert_true(vimtex#syntax#in('texTheoremEnvBgn', 17, 1))
call assert_true(vimtex#syntax#in('texTheoremEnvBgn', 21, 1))

call assert_true(vimtex#syntax#in('texTheoremEnvOpt', 13, 36))
call assert_true(vimtex#syntax#in('texCmdRefConcealed', 13, 42))
call assert_true(vimtex#syntax#in('texRefConcealedArg', 13, 47))

" Theorem names should be matched literally (#3311)
call assert_true(vimtex#syntax#in('texTheoremEnvBgn', 29, 1))
call assert_true(vimtex#syntax#in('texTheoremEnvBgn', 33, 1))
call assert_false(vimtex#syntax#in('texTheoremEnvBgn', 37, 1))

call vimtex#test#finished()
