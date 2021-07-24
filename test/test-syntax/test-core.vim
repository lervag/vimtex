source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texNewenvParm', 36, 36))

call assert_true(vimtex#syntax#in('texVerbZoneInline', 44, 36))

call assert_true(vimtex#syntax#in('texAuthorArg', 64, 20))
call assert_true(vimtex#syntax#in('texDelim', 64, 39))

call assert_true(vimtex#syntax#in('texNewthmArgPrinted', 38, 23))
call assert_true(vimtex#syntax#in('texEnvOpt', 114, 18))

call assert_true(vimtex#syntax#in('texCmdBibitem', 119, 3))
call assert_true(vimtex#syntax#in('texBibitemArg', 119, 13))
call assert_true(vimtex#syntax#in('texBibitemOpt', 120, 13))

call vimtex#test#finished()
