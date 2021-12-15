source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texNewenvParm', 36, 36))

call assert_true(vimtex#syntax#in('texVerbZoneInline', 44, 36))

call assert_true(vimtex#syntax#in('texAuthorArg', 64, 20))
call assert_true(vimtex#syntax#in('texDelim', 64, 39))

call assert_true(vimtex#syntax#in('texNewthmArgPrinted', 38, 23))
" call assert_true(vimtex#syntax#in('texTheoremEnvOpt', 114, 18))

call assert_true(vimtex#syntax#in('texMathZone', 119, 12))
call assert_true(vimtex#syntax#in('texMathText', 120, 12))
call assert_true(vimtex#syntax#in('texMathText', 121, 16))
call assert_true(vimtex#syntax#in('texMathText', 122, 12))
call assert_true(vimtex#syntax#in('texMathText', 123, 12))

call assert_true(vimtex#syntax#in('texCmdBibitem', 127, 3))
call assert_true(vimtex#syntax#in('texBibitemArg', 127, 13))
call assert_true(vimtex#syntax#in('texBibitemOpt', 128, 13))

call vimtex#test#finished()
