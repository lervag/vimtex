source common.vim

silent edit test-amsmath.tex

set spell

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texCmdDeclmathoper', 4, 1))
call assert_true(vimtex#syntax#in('texDeclmathoperArgName', 4, 22))
call assert_true(vimtex#syntax#in('texDeclmathoperArgBody', 4, 27))

call assert_true(vimtex#syntax#in('texCmdOpname', 5, 18))
call assert_true(vimtex#syntax#in('texOpnameArg', 5, 32))

call assert_true(vimtex#syntax#in('texCmdNumberWithin', 7, 1))
call assert_true(vimtex#syntax#in('texNumberWithinArg1', 7, 15))
call assert_true(vimtex#syntax#in('texNumberWithinArg2', 7, 25))

call assert_true(vimtex#syntax#in('texCmdSubjClass', 9, 1))
call assert_true(vimtex#syntax#in('texSubjClassOpt', 9, 12))
call assert_true(vimtex#syntax#in('texSubjClassArg', 9, 18))

call vimtex#test#finished()
