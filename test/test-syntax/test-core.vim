source common.vim

silent edit test-core.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texNewenvParm', 36, 36))

call assert_true(vimtex#syntax#in('texVerbZoneInline', 42, 36))

call assert_true(vimtex#syntax#in('texAuthorArg', 62, 20))
call assert_true(vimtex#syntax#in('texDelim', 62, 39))

call vimtex#test#finished()
