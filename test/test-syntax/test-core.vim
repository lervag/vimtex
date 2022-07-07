source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texNewenvParm', 37, 36))

call assert_true(vimtex#syntax#in('texVerbZoneInline', 45, 36))

call assert_true(vimtex#syntax#in('texAuthorArg', 65, 20))
call assert_true(vimtex#syntax#in('texDelim', 65, 39))

call assert_true(vimtex#syntax#in('texNewthmArgPrinted', 39, 23))
" call assert_true(vimtex#syntax#in('texTheoremEnvOpt', 115, 18))

call assert_true(vimtex#syntax#in('texMathTextConcArg', 106, 59))
call assert_true(vimtex#syntax#in('texMathTextConcArg', 105, 59))

call assert_true(vimtex#syntax#in('texCmdBibitem', 124, 3))
call assert_true(vimtex#syntax#in('texBibitemArg', 124, 13))
call assert_true(vimtex#syntax#in('texBibitemOpt', 125, 13))

call vimtex#test#finished()
