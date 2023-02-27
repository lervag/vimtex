source common.vim

EditConcealed test-optidef.tex

if empty($INMAKE) | finish | endif

call assert_true(vimtex#syntax#in('texMathZoneEnv', 7, 1))
call assert_true(vimtex#syntax#in('texMathZoneEnv', 11, 1))
call assert_true(vimtex#syntax#in('texMathZoneEnv', 15, 1))
call assert_true(vimtex#syntax#in('texMathZoneEnv', 19, 1))
call assert_true(vimtex#syntax#in('texMathZoneEnv', 23, 1))
call assert_true(vimtex#syntax#in('texMathZoneEnv', 27, 1))

call vimtex#test#finished()
